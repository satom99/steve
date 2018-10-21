defmodule Steve.Storage.Redis.Atomic do
  @moduledoc false

  alias Steve.Storage.Redis.Pool

  @private Path.join(:code.priv_dir(:steve), "redis")
  @dequeue "a4c1cb2b35ca2479f935fa8cb906cc0a45df0f59"
  @expired "8477882aa6f6448412f85cc6e134659cea9c66d8"
  @recover "5b12847fddb9fbb655e94d2ae120824252491d48"

  def dequeue(from, score, node, count) do
    eval = ["EVALSHA", @dequeue, 3, from, score, node, count]
    execute(eval, "dequeue.lua")
  end

  def expired(from, score) do
    eval = ["EVALSHA", @expired, 2, from, score]
    execute(eval, "expired.lua")
  end

  def recover(from) do
    eval = ["EVALSHA", @recover, 1, from]
    execute(eval, "recover.lua")
  end

  defp execute(eval, file) do
    case Pool.command(eval) do
      {:ok, result} ->
        {:ok, result}
      {:error, "NOSCRIPT"} ->
        content = @private
        |> Path.join(file)
        |> File.read!

        load = ["SCRIPT", "LOAD", content]
        cmds = [load, eval]

        Pool.transaction(cmds)
      {:error, reason} ->
        {:error, reason}
    end
  end
end
