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
        error("Job #{id} on #{queue} failed. \n #{format}")
    end

    defdelegate debug(message), to: Logger
    defdelegate error(message), to: Logger
end