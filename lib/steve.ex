defmodule Steve do
    use Application

    alias Steve.{Config, Time}
    alias Steve.{Queue, Storage, Job}

    @doc false
    def start(_type, _args) do
        children = [
            Storage
        ]
        options = [
            strategy: :one_for_one,
            name: __MODULE__
        ]
        Supervisor.start_link(children, options)
    end

    @doc false
    def start_phase(:queues, _type, _args) do
        :queues
        |> Config.get([])
        |> Enum.each(&Queue.create/1)
    end

    @doc """
    Schedules a job to be performed at a given time.
    """
    @spec enqueue(Job.t, DateTime.t) :: :ok

    defdelegate enqueue(job, time \\ Time.now()), to: Storage
end