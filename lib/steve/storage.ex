defmodule Steve.Storage do
    @moduledoc """
    Defines a behaviour for storage adapters to implement.
    """
    alias Steve.Config
    alias Steve.Job

    @doc false
    def start_link(state) do
        adapter().start_link(state)
    end

    @doc false
    def child_spec(state) do
        adapter().child_spec(state)
    end

    @doc false
    def ack!(job) do
        adapter().ack!(job)
    end

    @doc false
    def retry!(job) do
        adapter().retry!(job)
    end

    @doc false
    def recover!(queue) do
        adapter().recover!(queue)
    end

    @doc false
    def enqueue(job, time) do
        adapter().enqueue(job, time)
    end

    @doc false
    def dequeue(queue, count) do
        adapter().dequeue(queue, count)
    end

    defp adapter do
        Config.get!(:storage)
    end

    defmacro __using__(_options) do
        quote do
            @behaviour Steve.Storage

            alias Steve.{Config, Time}
            alias Steve.Job

            @doc false
            def start_link(_state) do
                :ignore
            end
            defoverridable [start_link: 1]

            @doc false
            def child_spec(options) do
                %{
                    id: __MODULE__,
                    type: :supervisor,
                    start: {__MODULE__, :start_link, [options]}
                }
            end
            defoverridable [child_spec: 1]
        end
    end

    @doc """
    Called after a job has been performed successfully.
    """
    @callback ack!(Job.t) :: :ok | no_return

    @doc """
    Called after an error is encountered when performing a job.
    """
    @callback retry!(Job.t) :: :ok | no_return

    @doc """
    Called upon start to hopefully recover orphaned jobs.
    """
    @callback recover!(String.t) :: :ok | no_return

    @doc """
    Called to enqueue a given job to be performed at a specific time.
    """
    @callback enqueue(Job.t, DateTime.t) :: :ok | term

    @doc """
    Called to dequeue a specific amount of jobs.
    """
    @callback dequeue(String.t, pos_integer) :: list
end