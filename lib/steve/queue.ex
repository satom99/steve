defmodule Steve.Queue do
  use Supervisor

  alias Steve.Queue.{Handler, Worker}

  defstruct [
    size: 5,
    polling: 5000,
    name: :default
  ]

  @type config :: [
    size: 5 | pos_integer,
    polling: 5000 | pos_integer,
    name: :default | term
  ]

  @doc """
  Subscribes to a queue with the given configuration.
  """
  @spec create(config) :: Supervisor.on_start_child

  def create(options) do
    arguments = struct(__MODULE__, options)
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

  defp child_spec(%{name: name} = arguments) do
    super(arguments)
    |> Map.put(:id, name)
  end
end
