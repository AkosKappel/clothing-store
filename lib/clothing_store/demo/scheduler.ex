defmodule ClothingStore.Demo.Scheduler do
  @moduledoc """
  Runs `ClothingStore.Demo.Reset.run/0` every day at the configured local time.
  Started only when DEMO_RESET_ENABLED is true.
  """
  use GenServer
  require Logger

  alias ClothingStore.Demo

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    state = %{
      settings: Demo.reset_settings(),
      # tests swap in their own reset
      run: Keyword.get(opts, :run, &Demo.Reset.run/0),
      last: nil,
      next: nil
    }

    {:ok, schedule(state)}
  end

  @impl true
  def handle_info({:reset, target}, state) do
    try do
      state.run.()
    rescue
      e -> Logger.error("Demo reset failed: " <> Exception.format(:error, e, __STACKTRACE__))
    end

    {:noreply, schedule(%{state | last: target})}
  end

  # Counting from the last target as well as from now: if the clock steps back
  # after a reset, the same target can't come round again.
  defp schedule(%{settings: %{time: time, timezone: tz}, last: last} = state) do
    now = DateTime.utc_now()
    from = if last && DateTime.after?(last, now), do: last, else: now
    next = next_run(from, time, tz)
    Logger.info("Next demo reset at #{DateTime.shift_zone!(next, tz)}")
    Process.send_after(self(), {:reset, next}, DateTime.diff(next, now, :millisecond))
    %{state | next: next}
  end

  @doc "Next moment after `now` (UTC) when the local clock in `tz` shows `at`."
  def next_run(%DateTime{} = now, %Time{} = at, tz) do
    today = now |> DateTime.shift_zone!(tz) |> DateTime.to_date()
    candidate = local(today, at, tz)

    if DateTime.compare(candidate, now) == :gt,
      do: candidate,
      else: local(Date.add(today, 1), at, tz)
  end

  defp local(date, time, tz) do
    case DateTime.new(date, time, tz) do
      {:ok, dt} -> dt
      {:ambiguous, first, _second} -> first
      {:gap, _before, just_after} -> just_after
    end
    |> DateTime.shift_zone!("Etc/UTC")
  end
end
