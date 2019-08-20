defmodule Steve.Storage.Ecto do
    @moduledoc """
    A storage adapter that uses Ecto to interact with a database.

    ### Configuration

    The application must be configured as shown below.
    ```elixir
    config :steve,
    [
        storage: Steve.Storage.Ecto,
        repository: Example.Repo
    ]
    ```
    Where `Example.Repo` should be a valid `Ecto.Repo` instance.

    ### Migrations

    One must also define the following migration within their application.
    ```elixir
    defmodule Example.Repo.Migrations.Steve do
        use Ecto.Migration

        defdelegate change, to: Steve.Storage.Ecto.Migration
    end
    ```
    """
    use Steve.Storage

    import Ecto.Query

    alias Steve.Storage.Ecto.Schema

    def enqueue(%Job{id: id, queue: queue} = job, %DateTime{} = time) do
        params = %{
            uuid: id,
            queue: "#{queue}",
            content: encode(job),
            execute_at: time
        }
        object = Schema.changeset(params)

        case insert(object) do
            {:ok, _struct} -> :ok
            other -> other
        end
    end

    def dequeue(queue, count) do
        handler = fn ->
            select = from(
                job in Schema,
                lock: "FOR UPDATE",
                where: job.execute_at <= ^Time.now(),
                where: job.status == ^:queued,
                where: job.queue == ^"#{queue}",
                order_by: [asc: job.retry],
                order_by: job.inserted_at,
                limit: ^count
            )
            list = all(select)
            uuid = Enum.map(list, & &1.id)
            changes = [
                set: [status: :running, node: Config.node()],
                inc: [retry: 1]
            ]
            update = from(
                job in Schema,
                where: job.id in ^uuid
            )
            update_all(update, changes)
            Enum.map(list, &decode/1)
        end
        {:ok, list} = transaction(handler)
        list
    end

    def ack!(%Job{id: id}) do
        query = from(
            job in Schema,
            where: job.status == ^:running,
            where: job.uuid == ^id
        )
        delete_all(query)
        :ok
    end

    def retry!(%Job{id: id, queue: queue, worker: worker, max_retries: maximum, expiry_days: expiry}) do
        stored = get_by!(status: :running, uuid: id)
        changes = case stored do
            %{retry: count} when count < maximum ->
                offset = worker.backoff(count)
                future = Time.offset_now(offset)
                [status: :queued, execute_at: future]
            _other ->
                expiry = expiry * (24 * 60 * 60)
                future = Time.offset_now(expiry)
                [status: :failed, expiry_at: future]
        end
        object = Schema.changeset(stored, changes)

        case update(object) do
            {:ok, %{status: :failed}} ->
                expired(queue)
            {:ok, _struct} ->
                :ok
        end
    end

    def recover!(queue) do
        query = from(
            job in Schema,
            where: job.node == ^Config.node(),
            where: job.status == ^:running,
            where: job.queue == ^"#{queue}"
        )
        changes = [
            set: [status: :queued, node: nil],
            inc: [retry: -1]
        ]
        update_all(query, changes)
        :ok
    end

    defp expired(queue) do
        query = from(
            job in Schema,
            where: job.expiry_at <= ^Time.now(),
            where: job.status == ^:failed,
            where: job.queue == ^"#{queue}"
        )
        delete_all(query)
        :ok
    end

    defp encode(term) do
        :erlang.term_to_binary(term)
    end

    defp decode(%Schema{content: binary}) do
        :erlang.binary_to_term(binary)
    end

    defp repository do
        Config.get!(:repository)
    end

    defp transaction(handler) do
        repository().transaction(handler)
    end

    defp get_by!(clauses) do
        repository().get_by!(Schema, clauses)
    end

    defp insert(changeset) do
        repository().insert(changeset)
    end

    defp update(changeset) do
        repository().update(changeset)
    end

    defp all(query) do
        repository().all(query)
    end

    defp update_all(query, changes) do
        repository().update_all(query, changes)
    end

    defp delete_all(query) do
        repository().delete_all(query)
    end
end