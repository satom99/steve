defmodule Steve.Storage.Redis do
  use Steve.Storage

  alias Steve.Storage.Redis.{Pool, Atomic}

  defdelegate start_link(state), to: Pool

  def enqueue(%Job{id: id, queue: queue} = job, %DateTime{} = time) do
    score = Time.score(time)
    query = [
      ["HMSET", jobs(id), "queue", queue, "content", job, "retry", 0],
      ["ZADD", queued(queue), score, id]
    ]

    case Pool.transaction(query) do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
    end
  end

  def dequeue(queue, count) do
    from = queued(queue)
    score = Time.score()
    node = Config.node()

    case Atomic.dequeue(from, score, node, count) do
      {:ok, list} ->
        list
        |> Enum.map(&decode/1)
        |> Enum.filter(& &1)
      {:error, reason} -> reason
    end
  end

  def ack(%Job{id: id, queue: queue}) do
    query = [
      ["HDEL", jobs(id)],
      ["LREM", running(queue), "-1", id]
    ]

    case Pool.transaction(query) do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
    end
  end

  def retry(%Job{id: id, queue: queue, worker: worker, max_retries: maximum, expiry_days: expiry}) do
    current = ["HGET", jobs(id), "retry"]
    command = case Pool.command(current) do
      {:ok, count} when count < maximum  ->
        offset = worker.backoff(count)
        future = Time.offset_now(offset)
        score = Time.score(future)
        ["ZADD", queued(queue), score, id]
      {:ok, _count} ->
        expiry = expiry * (24 * 60 * 60)
        future = Time.offset_now(expiry)
        score = Time.score(future)
        ["ZADD", failed(queue), score, id]
    end
    remove = ["LREM", running(queue), "-1", id]
    query = [command, remove]

    case Pool.transaction(query) do
      {:ok, _result} ->
        expired(queue)
        :ok
      {:error, _reason} ->
        :error
    end
  end

  def recover!(queue) do
    case Atomic.recover(queue) do
      {:ok, _result} ->
        :ok
    end
  end

  defp expired(queue) do
    score = Time.score()
    Atomic.expired(queue, score)
  end

  defp decode(binary) do
    :erlang.binary_to_term(binary)
  rescue
    _malformed -> false
  end

  defp jobs(uuid) do
    "steve:jobs:#{uuid}"
  end

  defp queued(queue) do
    "steve:#{queue}:queued"
  end

  defp running(queue) do
    "steve:#{queue}:running:#{Config.node()}"
  end

  defp failed(queue) do
    "steve:#{queue}:failed"
  end
end
