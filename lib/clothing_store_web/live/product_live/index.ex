defmodule ClothingStoreWeb.ProductLive.Index do
  @moduledoc """
  The dashboard: products as a photo grid or a compact list (`?view=list`),
  loaded 24 at a time as the visitor scrolls. Changes by other visitors stream
  in live: new products at the top, edits in place with a short highlight.
  """
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.{ActivityComponents, Helpers}

  alias ClothingStore.{ActivityFeed, Products}
  alias ClothingStoreWeb.Presence

  @per_page 24
  @recent_activity 4
  # how long a product changed by someone else stays highlighted (matches .live-highlight)
  @highlight_ms 2_500

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, Presence.online_topic())
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "activity")
    end

    {:ok,
     socket
     |> assign(page_title: "Dashboard", view: "grid", highlighted: %{}, announcement: nil)
     |> assign(:online, Presence.online_count())
     |> stream(:activity, ActivityFeed.recent(@recent_activity), limit: @recent_activity)
     |> stream_configure(:products, dom_id: &"product-#{&1.id}")
     |> load_first_page()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    view = if params["view"] == "list", do: "list", else: "grid"

    # stream items render once, so switching the layout re-renders the loaded ones
    if view == socket.assigns.view,
      do: {:noreply, socket},
      else: {:noreply, socket |> assign(:view, view) |> reload_loaded()}
  end

  @impl true
  def handle_event("load_more", _params, %{assigns: %{end_of_list: true}} = socket),
    do: {:noreply, socket}

  def handle_event("load_more", _params, socket) do
    products = Products.page_products(socket.assigns.loaded, @per_page)

    {:noreply,
     socket
     |> stream(:products, products)
     |> track_loaded(products)}
  end

  @impl true
  def handle_info({:product_created, product}, socket) do
    socket =
      socket
      |> update(:total, &(&1 + 1))
      |> update(:loaded, &(&1 + 1))
      |> update(:ids, &MapSet.put(&1, product.id))

    {:noreply, highlight(socket, product, "New product: #{product.title}", at: 0)}
  end

  def handle_info({:product_updated, product}, socket) do
    # products further down appear with their new data once they're scrolled to
    if MapSet.member?(socket.assigns.ids, product.id),
      do: {:noreply, highlight(socket, product, "#{product.title} was updated", [])},
      else: {:noreply, socket}
  end

  def handle_info({:product_deleted, product}, socket) do
    loaded? = MapSet.member?(socket.assigns.ids, product.id)

    {:noreply,
     socket
     |> stream_delete(:products, product)
     |> update(:total, &(&1 - 1))
     |> update(:loaded, &if(loaded?, do: &1 - 1, else: &1))
     |> update(:ids, &MapSet.delete(&1, product.id))
     |> update(:highlighted, &Map.delete(&1, product.id))
     |> assign(:announcement, "#{product.title} was deleted")}
  end

  def handle_info({:unhighlight, id}, socket) do
    case Map.pop(socket.assigns.highlighted, id) do
      {nil, _highlighted} ->
        {:noreply, socket}

      {product, highlighted} ->
        {:noreply,
         socket |> assign(:highlighted, highlighted) |> stream_insert(:products, product)}
    end
  end

  def handle_info(:demo_reset, socket) do
    {:noreply,
     socket
     |> load_first_page()
     |> stream(:activity, ActivityFeed.recent(@recent_activity),
       reset: true,
       limit: @recent_activity
     )}
  end

  def handle_info({:activity, event}, socket),
    do: {:noreply, stream_insert(socket, :activity, event, at: 0, limit: @recent_activity)}

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket),
    do: {:noreply, assign(socket, :online, Presence.online_count())}

  defp load_first_page(socket) do
    products = Products.page_products(0, @per_page)

    socket
    |> assign(total: Products.count_products(), loaded: 0, ids: MapSet.new(), highlighted: %{})
    |> stream(:products, products, reset: true)
    |> track_loaded(products)
  end

  defp reload_loaded(socket) do
    products = Products.page_products(0, max(socket.assigns.loaded, @per_page))

    socket
    |> assign(loaded: 0, ids: MapSet.new())
    |> stream(:products, products, reset: true)
    |> track_loaded(products)
  end

  defp track_loaded(socket, products) do
    loaded = socket.assigns.loaded + length(products)

    socket
    |> assign(:loaded, loaded)
    |> update(:ids, &Enum.into(products, &1, fn product -> product.id end))
    |> assign(:end_of_list, loaded >= socket.assigns.total or products == [])
  end

  defp highlight(socket, product, announcement, opts) do
    Process.send_after(self(), {:unhighlight, product.id}, @highlight_ms)

    socket
    |> update(:highlighted, &Map.put(&1, product.id, product))
    |> stream_insert(:products, product, opts)
    |> assign(:announcement, announcement)
  end
end
