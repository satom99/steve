defmodule Steve.Logger do
  @moduledoc false

  require Logger

  alias Steve.Job

  def started(%Job{id: id, queue: queue}) do
    info("#{queue} - Job ##{id} started.")
  end

  def success(%Job{id: id, queue: queue}) do
    info("#{queue} - Job ##{id} done.")
  end

  def failed(%Job{id: id, queue: queue}) do
    warn("#{queue} - Job##{id} failed.")
  end

  defdelegate info(message), to: Logger
  defdelegate warn(message), to: Logger
  defdelegate error(message), to: Logger
end
