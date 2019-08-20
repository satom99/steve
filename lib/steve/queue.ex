defmodule Steve.Queue do
    alias Steve.Queue.{Handler, Worker}
    alias __MODULE__

    defstruct [
        size: 10,
        polling: 5000,
        name: :default
    ]
    @type options :: [
        size: 10 | pos_integer,
        polling: 5000 | pos_integer,
        name: :default | term
    ]

    @doc """
    Subscribes to a queue with the given configuration.
    """
    @spec create(options) :: Supervisor.on_start_child

    def create(options) do
        arguments = struct(Queue, options)
        child = child_spec(arguments)
        Supervisor.start_child(Steve, child)
    end

    @doc false
    def start_link(%{name: name, size: size} = options) do
        children = [
            poolboy(name, size),
            {Handler, options}
        ]
        options = [
            strategy: :one_for_one,
            name: name
        ]
        Supervisor.start_link(children, options)
    end

    defp poolboy(queue, size) do
        arguments = [
            size: size,
            max_overflow: 0,
            worker_module: Worker,
            name: {:local, :"#{queue}.pool"}
        ]
        :poolboy.child_spec(:pool, arguments)
    end

    defp child_spec(%{name: name} = options) do
        %{
            id: name,
            type: :supervisor,
            start: {Queue, :start_link, [options]}
        }
    end
end