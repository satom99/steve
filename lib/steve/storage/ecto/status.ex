defmodule Steve.Storage.Ecto.Status do
    @moduledoc false

    @behaviour Ecto.Type

    @values [queued: 0, running: 1, failed: 2]
    @atoms for {atom, _int} <- @values, do: atom

    def type, do: :integer

    def cast(value) when is_integer(value) do
        {:ok, value}
    end
    def cast(atom) when is_atom(atom) do
        cond do
            value = Keyword.get(@values, atom) ->
                {:ok, value}
            true ->
                :error
        end
    end
    def cast(_other), do: :error

    def load(value) when is_integer(value) do
        cond do
            atom = Enum.at(@atoms, value) ->
                {:ok, atom}
            true ->
                :error
        end
    end
    def load(_other), do: :error

    def dump(term) do
        cast(term)
    end
end