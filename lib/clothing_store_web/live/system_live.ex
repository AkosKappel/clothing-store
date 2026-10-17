defmodule ClothingStoreWeb.SystemLive do
  @moduledoc """
  A public, read-only look inside the running Erlang VM, refreshed every second.
  Only harmless numbers: no process names, no configuration, no request data.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Demo
  alias ClothingStore.Demo.Scheduler

  @tick_ms 1_000

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      System
      <:subtitle>
        The Erlang VM behind this demo, live. Every number updates once a second over the
        same LiveView connection the dashboard uses.
      </:subtitle>
    </.header>

    <dl class="grid grid-cols-2 gap-4 lg:grid-cols-4">
      <div :for={{label, value, icon} <- tiles(@stats)} class="card p-5">
        <dt class="flex items-center gap-2 text-sm text-gray-500">
          <.icon name={icon} class="size-5" /> {label}
        </dt>
        <dd class="mt-2 text-2xl font-semibold text-gray-900 tabular-nums">{value}</dd>
      </div>
    </dl>

    <section class="card mt-8 p-5 sm:p-6" aria-labelledby="versions-title">
      <h2 id="versions-title" class="font-semibold text-gray-900">Versions</h2>
      <dl class="mt-4 grid gap-x-8 gap-y-2 text-sm sm:grid-cols-2">
        <div :for={{name, version} <- @versions} class="flex justify-between gap-4">
          <dt class="text-gray-500">{name}</dt>
          <dd class="font-medium text-gray-900 tabular-nums">{version}</dd>
        </div>
      </dl>
    </section>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(@tick_ms, :tick)

    {:ok,
     assign(socket,
       page_title: "System",
       meta_description:
         "Live numbers from the Erlang VM that runs the Modern Fashion Store demo.",
       versions: versions(),
       stats: stats()
     )}
  end

  @impl true
  def handle_info(:tick, socket), do: {:noreply, assign(socket, :stats, stats())}

  @doc "A snapshot of the VM's numbers."
  def stats(now \\ DateTime.utc_now()) do
    {uptime_ms, _since_last} = :erlang.statistics(:wall_clock)
    reset = Demo.reset_settings()

    %{
      uptime_s: div(uptime_ms, 1000),
      processes: :erlang.system_info(:process_count),
      memory_mb: :erlang.memory(:total) / 1_048_576,
      schedulers: :erlang.system_info(:schedulers_online),
      run_queue: :erlang.statistics(:total_run_queue_lengths),
      next_reset_s:
        reset.enabled && DateTime.diff(Scheduler.next_run(now, reset.time, reset.timezone), now)
    }
  end

  defp tiles(stats) do
    [
      {"Uptime", duration(stats.uptime_s), "hero-clock"},
      {"Processes", format_int(stats.processes), "hero-cpu-chip"},
      {"Memory", "#{:erlang.float_to_binary(stats.memory_mb, decimals: 1)} MB",
       "hero-circle-stack"},
      {"Next demo reset", (stats.next_reset_s && duration(stats.next_reset_s)) || "Off",
       "hero-arrow-path"},
      {"Schedulers", stats.schedulers, "hero-squares-2x2"},
      {"Run queue", stats.run_queue, "hero-queue-list"}
    ]
  end

  @doc "Seconds as `3d 4h`, `4h 05m`, `5m 07s` or `7s`."
  def duration(s) when s >= 86_400, do: "#{div(s, 86_400)}d #{div(rem(s, 86_400), 3600)}h"
  def duration(s) when s >= 3600, do: "#{div(s, 3600)}h #{pad(div(rem(s, 3600), 60))}m"
  def duration(s) when s >= 60, do: "#{div(s, 60)}m #{pad(rem(s, 60))}s"
  def duration(s), do: "#{s}s"

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  defp format_int(n),
    do: n |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+$)/, " ")

  defp versions do
    [
      {"Elixir", System.version()},
      {"Erlang/OTP", System.otp_release()},
      {"Phoenix", to_string(Application.spec(:phoenix, :vsn))},
      {"Phoenix LiveView", to_string(Application.spec(:phoenix_live_view, :vsn))},
      {"Ecto SQL", to_string(Application.spec(:ecto_sql, :vsn))},
      {"Bandit", to_string(Application.spec(:bandit, :vsn))}
    ]
  end
end
