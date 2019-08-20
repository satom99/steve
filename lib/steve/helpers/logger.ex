defmodule Steve.Logger do
    @moduledoc false

    require Logger

    alias Steve.Job

    def started(%Job{id: id, queue: queue}) do
        debug("Job #{id} on #{queue} started.")
    end

    def success(%Job{id: id, queue: queue}) do
        debug("Job #{id} on #{queue} succeeded.")
    end

    def failed(%Job{id: id, queue: queue}, exception, stacktrace) do
        format = Exception.format(:error, exception, stacktrace)
        warn("Job #{id} on #{queue} failed. \n #{format}")
    end

    defdelegate warn(message), to: Logger
    defdelegate debug(message), to: Logger
    defdelegate error(message), to: Logger
end