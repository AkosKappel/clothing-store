defmodule ClothingStore.Products.ProductNotifier do
  use GenServer
  alias ClothingStore.PubSub

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Phoenix.PubSub.subscribe(PubSub, "products")
    {:ok, state}
  end

  def handle_info({:product_created, product}, state) do
    IO.puts("[handle_info] Product #{product.id} created: #{inspect(product)} ")
    {:noreply, state}
  end

  def handle_info({:product_updated, product}, state) do
    IO.puts("[handle_info] Product #{product.id} updated: #{inspect(product)} ")
    {:noreply, state}
  end

  def handle_info({:product_deleted, product}, state) do
    IO.puts("[handle_info] Product #{product.id} deleted: #{inspect(product)} ")
    {:noreply, state}
  end
end
