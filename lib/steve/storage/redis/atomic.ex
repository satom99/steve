defmodule Steve.Storage.Redis.Atomic do
  @moduledoc false

  alias Steve.Storage.Redis.Pool

  @private :code.priv_dir(:steve)
  @dequeue "10f40f427e58be26e8c82d399fa3b2220f716748"
  @expired "10f40f427e58be26e8c82d399fa3b2220f716748"
  @recover "10f40f427e58be26e8c82d399fa3b2220f716748"

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
