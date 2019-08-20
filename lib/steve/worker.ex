defmodule Steve.Worker do
    @moduledoc """
    Defines a behaviour for workers to implement.

    Be sure to `use` this module for defaults to be injected.
    """
    defmacro __using__(_options) do
        quote do
            @behaviour Steve.Worker

            def backoff(retry) do
                :math.pow(retry, 4) + 15 + Enum.random(0..30) * (retry + 1)
            end
            defoverridable [backoff: 1]
        end
    end

    @doc """
    Called when a job is to be preformed.
    """
    @callback perform(... :: any) :: any

    @doc """
    Called to determine a retry time offset in seconds.

    Check the source code for the default implementation.
    """
    @callback backoff(retry :: pos_integer) :: non_neg_integer
    @optional_callbacks [backoff: 1]
end