defmodule Steve.Config do
  @moduledoc false

  import Application

  def get(key, default \\ nil) do
    get_env(:steve, key, default)
  end

  def get!(key) do
    case get(key) do
      nil -> raise "Please configure '#{key}'."
      value -> value
    end
  end

  def node do
    case get(:node) do
      nil ->
        {:ok, name} = :inet.gethostname()
        to_string(name)
      value ->
        value
    end
  end
end
