defmodule ClothingStore.Products.Purger do
  @moduledoc "Every minute, deletes for good the products whose undo window has passed."
  use GenServer

  alias ClothingStore.Products

  @interval :timer.minutes(1)

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    Process.send_after(self(), :purge, @interval)
    {:ok, nil}
  end

  @impl true
  def handle_info(:purge, state) do
    Products.purge_deleted()
    Process.send_after(self(), :purge, @interval)
    {:noreply, state}
  end
end
