defmodule Example.Repo.Migrations.Steve do
  use Ecto.Migration

  def change do
    create table(:steve) do
      add :uuid, :string
      add :node, :string
      add :queue, :string
      add :content, :binary
      add :expiry_at, :utc_datetime
      add :execute_at, :utc_datetime
      add :status, :integer, default: 0
      add :retry, :integer, default: 0

      timestamps(type: :utc_datetime)
    end
  end
end
