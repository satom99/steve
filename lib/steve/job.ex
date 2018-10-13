defmodule Steve.Job do
  alias Ecto.UUID

  @enforce_keys [:queue, :worker]

  defstruct [
    :id,
    :queue,
    :worker,
    arguments: [],
    max_retries: 5,
    expiry_days: 7
  ]

  @type params :: [
    queue: term,
    worker: module,
    arguments: [] | list,
    max_retries: 5 | pos_integer,
    expiry_days: 7 | pos_integer
  ]

  @doc """
  Creates a job structure with the given params.

  This function injects multiple required fields.
  """
  @spec create(params) :: struct

  def create(params) do
    __MODULE__
    |> struct!(params)
    |> Map.put(:id, UUID.generate())
  end
end
