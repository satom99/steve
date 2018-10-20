defmodule Steve.Storage do
  @moduledoc false

  alias Steve.Job
  alias Steve.{Time, Config}

  def start_link(state) do
    adapter().start_link(state)
  end
  def child_spec(arguments) do
    adapter().child_spec(arguments)
  end

  def ack(job) do
    adapter().ack(job)
  end
  def retry(job) do
    adapter().retry(job)
  end
  def enqueue(job, time) do
    adapter().enqueue(job, time)
  end
  def dequeue(queue, count) do
    adapter().dequeue(queue, count)
  end
  def recover!(queue) do
    adapter().recover!(queue)
  end

  defp adapter do
    Config.get!(:storage)
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Steve.Storage

      alias Steve.{Time, Config}
      alias Steve.Job

      @doc false
      def start_link(_state) do
        :ignore
      end

      @doc false
      def child_spec(_options) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [:!]},
          type: :supervisor
        }
      end

      @doc false
      def ack(job)

      @doc false
      def retry(job)

      @doc false
      def enqueue(job, time)

      @doc false
      def dequeue(queue, count)

      @doc false
      def recover!(queue)

      defoverridable [start_link: 1]
      defoverridable [child_spec: 1]
    end
  end

  @callback ack(Job.t) :: :ok | :error
  @callback retry(Job.t) :: :ok | :error
  @callback enqueue(Job.t, DateTime.t) :: :ok | :error
  @callback dequeue(String.t, pos_integer) :: list | :error
  @callback recover!(String.t) :: :ok | no_return
end
