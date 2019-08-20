defmodule Steve.Queue.Handler do
    @moduledoc false

    use GenServer

    alias Steve.Logger
    alias Steve.Storage
    alias Steve.Queue.Worker

    @recover {:continue, :recover}

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
        {:ok, state, @recover}
    end

    def handle_continue(:recover, %{queue: queue} = state) do
        Storage.recover!(queue)
        {:noreply, state, 0}
    end

    def handle_info(:timeout, %{pool: pool, queue: queue, timeout: timeout} = state) do
        {_name, count, _overflow, _monitors} = :poolboy.status(pool)
        list = Storage.dequeue(queue, count)
        Enum.each(list, &perform(&1, state))
        {:noreply, state, timeout}
    end

    def handle_info({:DOWN, _mref, _process, worker, reason}, state) do
        %{pool: pool, monitors: monitors} = state
        [{_worker, job}] = :ets.lookup(monitors, worker)
        :ets.delete(monitors, worker)
        :poolboy.checkin(pool, worker)
        case reason do
            :normal ->
                success(job)
            {exception, stacktrace} ->
                failed(job, exception, stacktrace)
            exception ->
                failed(job, exception)
        end
        {:noreply, state, 0}
    end

    defp perform(job, %{pool: pool, monitors: monitors}) do
        worker = :poolboy.checkout(pool)
        :ets.insert(monitors, {worker, job})
        Process.monitor(worker)
        Worker.perform(worker, job)
        Logger.started(job)
    end

    defp success(job) do
        Storage.ack!(job)
        Logger.success(job)
    end

    defp failed(job, exception, stacktrace \\ []) do
        Storage.retry!(job)
        Logger.failed(job, exception, stacktrace)
    end
end