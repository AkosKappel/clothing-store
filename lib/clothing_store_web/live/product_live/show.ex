defmodule ClothingStoreWeb.ProductLive.Show do
  @moduledoc """
  One product: details, stock per size, the sales forecast, the QR label and the
  edit history. Edits, sales and restocks by anyone show up live; if someone
  deletes the product, the visitor is sent back to the inventory.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.{Products, Transactions}
  alias ClothingStoreWeb.ProductHTML

  # sales window for the stock forecast
  @forecast_days 30

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")

    {:ok, load(socket, Products.get_product!(id))}
  end

  @impl true
  def handle_info(
        {:product_deleted, %{id: id} = product},
        %{assigns: %{product: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("%{title} was deleted.", title: product.title))
     |> push_navigate(to: ~p"/products")}
  end

  def handle_info({:product_updated, %{id: id}}, %{assigns: %{product: %{id: id}}} = socket),
    do: {:noreply, load(socket, Products.get_product!(id))}

  # other products, and the nightly reset (which reconnects every LiveView anyway)
  def handle_info(_event, socket), do: {:noreply, socket}

  @impl true
  def render(assigns), do: ProductHTML.show(assigns)

  defp load(socket, product) do
    daily = Transactions.daily_units(product.id, @forecast_days)
    versions = Products.list_versions(product.id)
    sold = daily |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    assign(socket,
      page_title: product.title,
      product: product,
      forecast_days: @forecast_days,
      daily: daily,
      versions: versions,
      price_history: Products.price_history(versions),
      sold: sold,
      days_left: Transactions.days_of_stock_left(product.stock, sold, @forecast_days),
      reorder: Transactions.reorder_quantity(product.stock, sold)
    )
  end
end
