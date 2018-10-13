defmodule Steve.Worker do
  @moduledoc """
  Defines a behaviour all workers should follow.

  Be sure to `use` this module so that the defaults are injected.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour Steve.Worker

      def backoff(retry) do
        :math.pow(retry, 4) + 15 + Enum.random(0..30) * (retry + 1)
      end

      defoverridable [backoff: 1]
    end
  end

  @doc """
  Called when a job is to be performed.
  """
  @callback perform(... :: any) :: any

  @doc """
  Called to determine a retry time offset in seconds.

  Check the source code for the default implementation.
  """
  @callback backoff(retry :: pos_integer) :: non_neg_integer
  @optional_callbacks [backoff: 1]
end
