defmodule Steve.Queue.Worker do
  @moduledoc false

  use GenServer

  def start_link(_state) do
    GenServer.start_link(__MODULE__, :state)
  end
  def init(state), do: {:ok, state}

  def perform(worker, job) do
    GenServer.cast(worker, {:perform, job})
  end

  def handle_cast({:perform, job}, state) do
    %{worker: module, arguments: arguments} = job
    apply(module, :perform, arguments)
    {:stop, :normal, state}
  rescue
    exception ->
      {:stop, {exception, System.stacktrace}, state}
  end
end
