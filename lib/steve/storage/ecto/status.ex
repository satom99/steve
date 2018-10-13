defmodule Steve.Storage.Ecto.Status do
  @moduledoc false

  @behaviour Ecto.Type

  @values [queued: 0, running: 1, failed: 2]
  @atoms for {atom, int} <- @values, do: {int, atom}

  def type, do: :integer

  def cast(atom) when is_atom(atom) do
    cond do
      value = @values[atom] ->
        {:ok, value}
      true ->
        :error
    end
  end
  def cast(_other), do: :error

  def load(value) when is_integer(value) do
    cond do
      atom = @atoms[value] ->
        {:ok, atom}
      true ->
        :error
    end
  end
  def load(_other), do: :error

  def dump(term) when is_integer(term) do
    cond do
      :error = cast(term) ->
        :error
      true ->
        {:ok, term}
    end
  end
end
