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
        cond do
            value = get(:node) ->
                value
            Node.alive?() ->
                atom = Kernel.node()
                to_string(atom)
            true ->
                {:ok, name} = :inet.gethostname()
                to_string(name)
        end
    end
end