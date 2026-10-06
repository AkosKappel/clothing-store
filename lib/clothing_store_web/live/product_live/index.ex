defmodule ClothingStoreWeb.ProductLive.Index do
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.Helpers

  alias ClothingStore.Products

  # how long a product changed by someone else stays highlighted (matches .live-highlight)
  @highlight_ms 2_500

  @impl true
  def mount(_params, _session, socket) do
    # Fetch the initial list of products
    products = Products.list_products()

    # Subscribe to the "products" topic for real-time updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
    end

    {:ok,
     assign(socket,
       products: products,
       highlighted: MapSet.new(),
       announcement: nil,
       page_title: "Dashboard"
     )}
  end

  @impl true
  def handle_info({:product_created, product}, socket) do
    # Add the new product to the list
    socket = update(socket, :products, fn products -> [product | products] end)
    {:noreply, highlight(socket, product, "New product: #{product.title}")}
  end

  @impl true
  def handle_info({:product_updated, updated_product}, socket) do
    # Update the product in the list
    socket = update(socket, :products, &Enum.map(&1, fn p -> replace(p, updated_product) end))

    {:noreply, highlight(socket, updated_product, "#{updated_product.title} was updated")}
  end

  @impl true
  def handle_info({:product_deleted, deleted_product}, socket) do
    # Remove the deleted product from the list
    {:noreply,
     socket
     |> update(:products, fn products -> Enum.reject(products, &(&1.id == deleted_product.id)) end)
     |> assign(:announcement, "#{deleted_product.title} was deleted")}
  end

  @impl true
  def handle_info({:unhighlight, id}, socket) do
    {:noreply, update(socket, :highlighted, &MapSet.delete(&1, id))}
  end

  @impl true
  def handle_info(:demo_reset, socket) do
    {:noreply, assign(socket, :products, Products.list_products())}
  end

  defp replace(%{id: id}, %{id: id} = updated), do: updated
  defp replace(product, _updated), do: product

  defp highlight(socket, product, announcement) do
    Process.send_after(self(), {:unhighlight, product.id}, @highlight_ms)

    socket
    |> update(:highlighted, &MapSet.put(&1, product.id))
    |> assign(:announcement, announcement)
  end
end
