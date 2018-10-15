defmodule Steve.Storage.Ecto do
  @moduledoc """
  A storage adapter that uses Ecto to interact with a database.

  ### Requirements

  The database in use should suffice the following features:
  - Support for `RETURNING` statement on `UPDATE` queries.

  ### Configuration

  The application must be configured as shown below.
  ```elixir
  config :steve,
  [
    storage: Steve.Storage.Ecto,
    ecto_repos: [Example.Repo]
  ]
  ```
  Where `Example.Repo` should be a valid `Ecto.Repo` instance.

  ### Migrations

  In order to create the table that is to be used by the library,
  one may run the migrations that ship with the library by running
  both `mix ecto.create` and `mix ecto.migrate` directly at the
  application's root directory.
  """

  use Steve.Storage

  import Ecto.Query

  alias Steve.Storage.Ecto.Schema

  def start_link(_state) do
    repository()
    :ignore
  end

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
      {:error, _changeset} -> :error
    end
  end

  def dequeue(queue, count) do
    select = from(
      job in Schema,
      lock: "FOR UPDATE SKIP LOCKED",
      where: job.execute_at <= ^Time.now(),
      where: job.status == ^:queued,
      where: job.queue == ^"#{queue}",
      order_by: [asc: job.retry],
      order_by: job.inserted_at,
      limit: ^count
    )
    query = from(
      parent in Schema,
      join: child in subquery(select),
      on: child.id == parent.id
    )
    changes = [
      set: [status: :running, node: Config.node()],
      inc: [retry: 1]
    ]

    case update_all(query, changes) do
      {_count, list} ->
        list
        |> Enum.map(&decode/1)
        |> Enum.filter(& &1)
    end
  end

  def ack(%Job{id: id}) do
    query = from(
      job in Schema,
      where: job.status == ^:running,
      where: job.uuid == ^id
    )

    case delete_all(query) do
      {1, _nil} -> :ok
      _other -> :error
    end
  end

  def retry(%Job{id: id, worker: worker, max_retries: maximum, expiry_days: expiry}) do
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
      {:ok, %{status: :failed, queue: queue}} ->
        expired(queue)
      {:ok, _struct} ->
        :ok
      {:error, _changeset} ->
        :error
    end
  end

  def recover(queue) do
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
    update_all(query, changes, false)
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
  rescue
    _malformed -> false
  end

  defp repository do
    :ecto_repos
    |> Config.get!
    |> List.first
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

  defp update_all(query, changes, return \\ true) do
    repository().update_all(query, changes, returning: return)
  end

  defp delete_all(query) do
    repository().delete_all(query)
  end
end
