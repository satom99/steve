defmodule Steve.Queue.Handler do
  @moduledoc false

  use GenServer

  alias Steve.Logger
  alias Steve.Storage
  alias Steve.Queue.Worker

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  def init(%{name: name, polling: polling}) do
    state = %{
      queue: name,
      timeout: polling,
      pool: :"#{name}.pool",
      monitors: :ets.new(:monitors, read_concurrency: true)
    }
    send(self(), :recover)
    {:ok, state}
  end

  def handle_info(:recover, state) do
    Storage.recover!(state.queue)
    {:noreply, state, 0}
  end

  def handle_info(:timeout, state) do
    case pool_free(state.pool) do
      count when count > 0 ->
        case Storage.dequeue(state.queue, count) do
          list when is_list(list) ->
            Enum.each(list, &process(&1, state))
          error ->
            Logger.error("Failed to dequeue jobs: #{error}")
        end
        {:noreply, state, state.timeout}
      _other ->
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, mref, _process, worker, reason}, state) do
    :ok = :poolboy.checkin(state.pool, worker)
    case :ets.lookup(state.monitors, worker) do
      [{_worker, _mref, job}] ->
        demonitor!(state.monitors, worker, mref)
        case reason do
          :normal ->
            success(job)
          {exception, stacktrace} ->
            failed(job, exception, stacktrace)
          other ->
            failed(job, other, [])
        end
      _other ->
        :ignore
    end
    {:noreply, state, 0}
  end

  defp process(job, state) do
    worker = :poolboy.checkout(state.pool)
    monitor!(state.monitors, worker, job)
    Worker.perform(worker, job)
    Logger.started(job)
  end

  defp success(job) do
    :ok = Storage.ack(job)
    Logger.success(job)
  end

  defp failed(job, _exception, _stacktrace) do
    :ok = Storage.retry(job)
    Logger.failed(job)
  end

  defp monitor!(monitors, worker, job) do
    mref = Process.monitor(worker)
    true = :ets.insert(monitors, {worker, mref, job})
  end

  defp demonitor!(monitors, worker, mref) do
    true = Process.demonitor(mref, [:flush])
    true = :ets.delete(monitors, worker)
  end

  defp pool_free(pool) do
    {_name, count, _overflow, _monitors} = :poolboy.status(pool)
    count
  end
end
