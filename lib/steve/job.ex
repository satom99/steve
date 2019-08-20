defmodule Steve.Job do
    alias Ecto.UUID
    alias __MODULE__

    @enforce_keys [:queue, :worker]

    defstruct [
        :id,
        :queue,
        :worker,
        arguments: [],
        max_retries: 5,
        expiry_days: 7
    ]
    @type t :: %Job{
        queue: :term,
        worker: module,
        arguments: [] | list(term),
        max_retries: 5 | pos_integer,
        expiry_days: 7 | pos_integer
    }

    @doc """
    Creates a `t:t/0` structure with the given params.

    This function also injects additional required fields.
    """
    @spec create(keyword) :: t | no_return

    def create(params) do
        __MODULE__
        |> struct!(params)
        |> Map.put(:id, UUID.generate())
    end
end