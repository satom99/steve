defmodule Steve.Storage.Ecto.Schema do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset 

    alias Steve.Storage.Ecto.Status

    schema "steve" do
        field :uuid, :string
        field :node, :string
        field :queue, :string
        field :content, :binary
        field :expiry_at, :utc_datetime
        field :execute_at, :utc_datetime
        field :status, Status, default: 0
        field :retry, :integer, default: 0

        timestamps(type: :utc_datetime)
    end

    def changeset(struct \\ %__MODULE__{}, params) do
        fields = __schema__(:fields)
        params = Map.new(params)
        struct
        |> cast(params, fields)
        |> unique_constraint(:uuid)
    end
end