defmodule ClothingStoreWeb.ChartComponents do
  @moduledoc """
  Small server-rendered charts: no JavaScript, nothing for the content security
  policy to allow, and they update like any other markup.

  Follows the dataviz guidance: thin marks with 4px rounded ends on a flat
  baseline, 2px gaps between segments, a legend with values (colour is never
  the only cue), a per-mark tooltip, and a table view of the same data.
  """
  use Phoenix.Component

  @doc """
  A single-series column chart, for example revenue per month.

  Each bar is `%{label: "Oct", value: number, tooltip: "October 2026: 1 234,50 €"}`.
  The highest and the last bar get a direct label; every bar shows its tooltip on
  hover or keyboard focus.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :bars, :list, required: true
  attr :color, :string, default: "#2a78d6"
  attr :format, :any, required: true, doc: "formats a value for axis ticks and labels"

  def bar_chart(assigns) do
    values = Enum.map(assigns.bars, & &1.value)
    {step, ticks} = nice_scale(Enum.max(values, fn -> 0 end), 4)
    top = step * ticks

    highest =
      values |> Enum.with_index() |> Enum.max_by(&elem(&1, 0), fn -> {0, -1} end) |> elem(1)

    assigns =
      assign(assigns,
        top: top,
        ticks: for(i <- 0..ticks, do: i * step),
        labelled: MapSet.new([highest, length(values) - 1])
      )

    ~H"""
    <figure id={@id} aria-labelledby={"#{@id}-title"}>
      <figcaption id={"#{@id}-title"} class="sr-only">{@title}</figcaption>
      <div class="relative h-56 pl-14">
        <div
          :for={tick <- @ticks}
          class="absolute right-0 left-14 border-t border-gray-100"
          style={"bottom: #{percent(tick, @top)}%"}
          aria-hidden="true"
        >
          <span class="absolute -top-2 -left-14 w-12 text-right text-xs text-gray-500 tabular-nums">
            {@format.(tick)}
          </span>
        </div>
        <ol class="relative flex h-full items-end gap-1 border-b border-gray-300 sm:gap-2">
          <li
            :for={{bar, index} <- Enum.with_index(@bars)}
            class="group relative flex h-full flex-1 flex-col justify-end rounded-sm outline-none focus-visible:ring-2 focus-visible:ring-red-600"
            tabindex="0"
            aria-label={bar.tooltip}
          >
            <span
              :if={index in @labelled and bar.value > 0}
              class="mb-1 text-center text-[11px] font-medium text-gray-700 tabular-nums max-sm:hidden"
              aria-hidden="true"
            >
              {@format.(bar.value)}
            </span>
            <span
              class="mx-auto block w-full max-w-12 rounded-t-[4px] transition-opacity group-hover:opacity-80"
              style={"height: #{percent(bar.value, @top)}%; background-color: #{@color}"}
              aria-hidden="true"
            ></span>
            <span
              role="tooltip"
              class="pointer-events-none absolute bottom-full left-1/2 z-10 mb-2 hidden -translate-x-1/2 rounded-md bg-gray-900 px-2.5 py-1.5 text-xs whitespace-nowrap text-white shadow-lg group-hover:block group-focus:block"
            >
              {bar.tooltip}
            </span>
          </li>
        </ol>
      </div>
      <ol class="mt-2 flex gap-1 pl-14 sm:gap-2" aria-hidden="true">
        <li
          :for={{bar, index} <- Enum.with_index(@bars)}
          class={[
            "flex-1 text-center text-xs text-gray-500",
            rem(length(@bars) - 1 - index, 2) == 1 && "max-sm:invisible"
          ]}
        >
          {bar.label}
        </li>
      </ol>
    </figure>
    """
  end

  @doc """
  A donut chart with a legend that lists each segment's value and share.

  Each segment is `%{label: "Shoes", value: number, color: "#008300", text: "1 234,50 €"}`.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :segments, :list, required: true
  attr :total_text, :string, required: true, doc: "shown in the middle of the ring"

  # circumference of r = 15.9155 is 100, so dash lengths are percentages
  @radius 15.9155
  @gap 0.6

  def donut_chart(assigns) do
    total = assigns.segments |> Enum.map(& &1.value) |> Enum.sum()

    {arcs, _offset} =
      Enum.map_reduce(assigns.segments, 0, fn segment, offset ->
        share = if total > 0, do: segment.value / total * 100, else: 0
        {Map.merge(segment, %{share: share, offset: offset}), offset + share}
      end)

    assigns = assign(assigns, arcs: arcs, radius: @radius, gap: @gap)

    ~H"""
    <figure
      id={@id}
      aria-labelledby={"#{@id}-title"}
      class="flex flex-col items-center gap-6 sm:flex-row lg:flex-col"
    >
      <figcaption id={"#{@id}-title"} class="sr-only">{@title}</figcaption>
      <div class="relative size-44 shrink-0">
        <svg viewBox="0 0 42 42" class="size-full -rotate-90" aria-hidden="true">
          <circle cx="21" cy="21" r={@radius} fill="none" stroke="#f3f4f6" stroke-width="6" />
          <circle
            :for={arc <- @arcs}
            :if={arc.share > 0}
            cx="21"
            cy="21"
            r={@radius}
            fill="none"
            stroke={arc.color}
            stroke-width="6"
            stroke-dasharray={"#{max(arc.share - @gap, 0.1)} #{100 - max(arc.share - @gap, 0.1)}"}
            stroke-dashoffset={-arc.offset}
          >
            <title>{arc.label}: {arc.text} ({round(arc.share)} %)</title>
          </circle>
        </svg>
        <div class="absolute inset-0 flex flex-col items-center justify-center text-center">
          <span class="text-xs text-gray-500">Total</span>
          <span class="text-sm font-semibold text-gray-900 tabular-nums">{@total_text}</span>
        </div>
      </div>
      <ul class="w-full min-w-0 space-y-2 text-sm">
        <li :for={arc <- @arcs} class="flex items-center gap-2">
          <svg class="size-2.5 shrink-0" viewBox="0 0 10 10" aria-hidden="true">
            <rect width="10" height="10" rx="2" fill={arc.color} />
          </svg>
          <span class="min-w-0 flex-1 truncate text-gray-700">{arc.label}</span>
          <span class="text-gray-900 tabular-nums">{arc.text}</span>
          <span class="w-10 text-right text-gray-500 tabular-nums">{round(arc.share)} %</span>
        </li>
      </ul>
    </figure>
    """
  end

  @doc """
  The data behind a chart as a table, collapsed under a "Show as table" toggle.

  Rows are lists of cell strings; the first cell is the row header.
  """
  attr :headers, :list, required: true
  attr :rows, :list, required: true

  def chart_table(assigns) do
    ~H"""
    <details class="mt-4 text-sm">
      <summary class="cursor-pointer font-medium text-gray-600 hover:text-gray-900">
        Show as table
      </summary>
      <table class="mt-3 w-full text-left">
        <thead class="text-gray-500">
          <tr>
            <th
              :for={{header, index} <- Enum.with_index(@headers)}
              scope="col"
              class={["py-1 font-medium", index > 0 && "text-right"]}
            >
              {header}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr :for={[first | rest] <- @rows}>
            <th scope="row" class="py-1 font-normal text-gray-700">{first}</th>
            <td :for={cell <- rest} class="py-1 text-right text-gray-900 tabular-nums">{cell}</td>
          </tr>
        </tbody>
      </table>
    </details>
    """
  end

  @doc """
  A step and tick count for an axis from 0 that covers `max` in about `ticks`
  readable steps (1, 2, 2.5 or 5 times a power of ten).

      iex> nice_scale(4_870, 4)
      {2000, 3}
  """
  def nice_scale(max, _ticks) when max <= 0, do: {1, 4}

  def nice_scale(max, ticks) do
    raw = max / ticks
    magnitude = :math.pow(10, :math.floor(:math.log10(raw)))
    step = Enum.find([1, 2, 2.5, 5, 10], &(&1 * magnitude >= raw)) * magnitude
    step = if step == trunc(step), do: trunc(step), else: step
    {step, ceil(max / step)}
  end

  defp percent(_value, top) when top <= 0, do: 0
  defp percent(value, top), do: Float.round(value / top * 100, 2)
end
