defmodule Steve.Storage.Redis.Pool do
  @moduledoc false

  alias Steve.Config

  def start_link(_state) do
    conf = Config.get!(:redix)
    spec = Redix.child_spec(conf)
    size = Config.get(:pool_size, 1)

    children = specifier(spec, size)
    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    Supervisor.start_link(children, options)
  end

  def command(command) do
    Redix.command(handler(), command)
  end

  def transaction(commands) do
    Redix.transaction_pipeline(handler(), commands)
  end

  defp specifier(spec, count) do
    for index <- 1..count do
      Map.put(spec, :id, index)
    end
  end

  defp handler do
    __MODULE__
    |> Supervisor.which_children
    |> Enum.random
    |> elem(1)
  end
end
