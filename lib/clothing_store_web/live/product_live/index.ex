defmodule ClothingStoreWeb.ProductLive.Index do
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.Helpers

  alias ClothingStore.Products

  @impl true
  def mount(_params, _session, socket) do
    # Fetch the initial list of products
    products = Products.list_products()

    # Subscribe to the "products" topic for real-time updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
    end

    # Assign the products to the socket
    {:ok, assign(socket, :products, products)}
  end

  @impl true
  def handle_info({:product_created, product}, socket) do
    # Add the new product to the list
    {:noreply, update(socket, :products, fn products -> [product | products] end)}
  end

  @impl true
  def handle_info({:product_updated, updated_product}, socket) do
    # Update the product in the list
    {:noreply, update(socket, :products, fn products ->
      Enum.map(products, fn product ->
        if product.id == updated_product.id, do: updated_product, else: product
      end)
    end)}
  end

  @impl true
  def handle_info({:product_deleted, deleted_product}, socket) do
    # Remove the deleted product from the list
    {:noreply, update(socket, :products, fn products ->
      Enum.reject(products, &(&1.id == deleted_product.id))
    end)}
  end
end
