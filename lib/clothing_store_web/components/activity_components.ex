defmodule ClothingStoreWeb.ActivityComponents do
  @moduledoc "The activity feed: one line per event, with an icon and a relative time."
  use ClothingStoreWeb, :html

  import ClothingStoreWeb.Helpers

  alias ClothingStore.ActivityFeed.Event

  @doc "A list of feed events, newest first, rendered from a stream."
  attr :id, :string, required: true
  attr :events, :any, required: true, doc: "a stream of `ActivityFeed.Event`s"
  attr :class, :any, default: nil

  def activity_list(assigns) do
    ~H"""
    <ol id={@id} phx-update="stream" class={["divide-y divide-gray-100", @class]}>
      <li :for={{dom_id, event} <- @events} id={dom_id} class="flex items-start gap-3 py-3">
        <span class={["mt-0.5 rounded-full p-1.5", icon_class(event.kind)]}>
          <.icon name={kind_icon(event.kind)} class="block size-4" />
        </span>
        <p class="min-w-0 flex-1 text-sm text-gray-800">
          <.event_text event={event} />
        </p>
        <time
          datetime={DateTime.to_iso8601(event.inserted_at)}
          title={format_date(event.inserted_at)}
          class="text-xs whitespace-nowrap text-gray-500"
        >
          {relative_time(event.inserted_at)}
        </time>
      </li>
    </ol>
    """
  end

  attr :event, Event, required: true

  defp event_text(%{event: %{kind: "sale"}} = assigns) do
    ~H"""
    Sale: {Enum.map_join(@event.data["items"], ", ", fn [title, quantity] ->
      "#{quantity} × #{title}"
    end)} · <span class="font-medium">{format_price(Decimal.new(@event.data["total"]))}</span>
    """
  end

  defp event_text(%{event: %{kind: "created"}} = assigns) do
    ~H"""
    New product: <.product_link event={@event} />
    """
  end

  defp event_text(%{event: %{kind: "deleted"}} = assigns) do
    ~H"""
    <span class="font-medium">{@event.product_title}</span> was deleted
    """
  end

  defp event_text(assigns) do
    ~H"""
    <.product_link event={@event} />{if @event.kind == "restocked", do: " restocked", else: ""}: {@event.data
    |> Map.get("changes", %{})
    |> Enum.map_join(" · ", &change_text/1)}
    """
  end

  attr :event, Event, required: true

  defp product_link(%{event: %{product_id: nil}} = assigns),
    do: ~H"""
    <span class="font-medium">{@event.product_title}</span>
    """

  defp product_link(assigns) do
    ~H"""
    <.link
      navigate={~p"/products/#{@event.product_id}"}
      class="font-medium hover:text-red-700 hover:underline"
    >
      {@event.product_title}
    </.link>
    """
  end

  @doc "One change as text: `stock 5 → 3`, `price 79,90 € → 69,90 €`, `description edited`."
  def change_text({field, _values}) when field in ["description", "photo"], do: "#{field} changed"

  def change_text({"price", [old, new]}),
    do:
      "price #{format_price(Decimal.new(to_string(old)))} → #{format_price(Decimal.new(to_string(new)))}"

  def change_text({"tags", [old, new]}),
    do: "tags #{Enum.join(old, ", ") |> blank_dash()} → #{Enum.join(new, ", ") |> blank_dash()}"

  def change_text({field, [old, new]}), do: "#{field} #{old} → #{new}"

  defp blank_dash(""), do: "–"
  defp blank_dash(text), do: text

  defp kind_icon("created"), do: "hero-plus-mini"
  defp kind_icon("deleted"), do: "hero-trash-mini"
  defp kind_icon("restocked"), do: "hero-arrow-up-tray-mini"
  defp kind_icon("sale"), do: "hero-shopping-bag-mini"
  defp kind_icon(_updated), do: "hero-pencil-mini"

  defp icon_class("sale"), do: "bg-emerald-50 text-emerald-700"
  defp icon_class("deleted"), do: "bg-rose-50 text-rose-700"
  defp icon_class("created"), do: "bg-sky-50 text-sky-700"
  defp icon_class(_other), do: "bg-gray-100 text-gray-600"
end
