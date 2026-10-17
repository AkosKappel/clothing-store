defmodule ClothingStoreWeb.ProductLive.Inventory do
  @moduledoc """
  The inventory table with its filters and sort, kept in the URL. Filtering
  patches the page instead of reloading it, and changes by other visitors
  (edits, sales, restocks, deletes) refresh the table live.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Products
  alias ClothingStoreWeb.ProductHTML

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")

    {:ok, assign(socket, page_title: gettext("Inventory"))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> assign(:filters, ProductHTML.filter_params(params)) |> load()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    # only what is set, so the URL stays short and shareable
    params =
      params
      |> Map.take(~w(q category min_price max_price in_stock low_stock sort tags))
      |> Map.reject(fn {_key, value} -> value in ["", [], "All", "newest"] end)

    {:noreply, push_patch(socket, to: ~p"/products?#{params}", replace: true)}
  end

  # product_created/updated/deleted and the nightly reset: the list is small, so reload it
  @impl true
  def handle_info(_event, socket), do: {:noreply, load(socket)}

  @impl true
  def render(assigns), do: ProductHTML.index(assigns)

  defp load(socket) do
    assign(socket,
      products: Products.list_products(socket.assigns.filters),
      categories: Products.list_categories(),
      tags: Products.list_tags()
    )
  end
end
