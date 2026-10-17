defmodule ClothingStoreWeb.StatisticsLive do
  @moduledoc """
  Sales statistics: summary tiles, revenue charts, stock alerts and bestsellers.
  New sales, product changes (stock, titles, deletions) and the nightly reset refresh it live.
  """
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.{Helpers, SalesComponents}

  alias ClothingStore.{Products, Transactions}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "transactions")
    end

    {:ok, socket |> assign(:page_title, "Statistics") |> load()}
  end

  @impl true
  def handle_info({event, _product}, socket)
      when event in [:product_created, :product_updated, :product_deleted],
      do: {:noreply, load(socket)}

  def handle_info(:demo_reset, socket), do: {:noreply, load(socket)}
  def handle_info({:transaction_created, _transaction}, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    this_month = Date.utc_today() |> Date.beginning_of_month()
    last_month = this_month |> Date.add(-1) |> Date.beginning_of_month()
    monthly = Transactions.monthly_sales(12)
    since = monthly |> hd() |> Map.fetch!(:month) |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    assign(socket,
      this_month: this_month,
      last_month: last_month,
      monthly: monthly,
      this: List.last(monthly),
      last: Enum.at(monthly, -2),
      categories: Transactions.revenue_by_category(since),
      discounts: Transactions.discounts_given(this_month),
      stock_alerts: Products.stock_alerts(),
      bestsellers: Transactions.list_bestsellers(3),
      this_month_bestsellers:
        Transactions.list_bestsellers_per_month(3, Date.to_string(this_month)),
      last_month_bestsellers:
        Transactions.list_bestsellers_per_month(3, Date.to_string(last_month))
    )
  end
end
