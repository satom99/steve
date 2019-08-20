defmodule Steve.Time do
    @moduledoc false

    import DateTime

    def now, do: utc_now()

    def offset_now(value) do
        now()
        |> to_unix(:microsecond)
        |> :erlang.+(value * 1000000)
        |> round
        |> from_unix!(:microsecond)
    end
end