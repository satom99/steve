defmodule Steve.Time do
  @moduledoc false

  import DateTime, except: [to_string: 1]

  def now, do: utc_now()

  def offset_now(value) do
    now()
    |> to_unix(:microseconds)
    |> :erlang.+(value * 1000000)
    |> round
    |> from_unix!(:microseconds)
  end

  def score(time \\ now()) do
    time
    |> to_unix(:microseconds)
    |> :erlang./(1000000)
    |> to_string
  end

  def future?(time) do
    diff(time, now()) > 0
  end
end
