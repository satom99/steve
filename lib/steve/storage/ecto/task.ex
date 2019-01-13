defmodule Mix.Tasks.Steve.Ecto.Migrate do
  @moduledoc """
  Refer to `Steve.Storage.Ecto` for more information.
  """

  use Mix.Task

  @doc false
  def run(args) do
    Mix.Tasks.Ecto.Create.run(args)
    Mix.Tasks.Ecto.Migrate.run(args)
  end
end
