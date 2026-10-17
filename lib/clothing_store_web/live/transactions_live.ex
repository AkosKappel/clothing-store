defmodule ClothingStoreWeb.TransactionsLive do
  @moduledoc """
  Sales grouped by month, 20 per page, filterable by month. The month and page
  live in the URL; new sales, product changes and the nightly reset refresh the page live.
  """
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.{Helpers, SalesComponents}

  alias ClothingStore.Transactions

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "transactions")
    end

    {:ok, assign(socket, page_title: "Transactions", per_page: @per_page)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {selected_month, month} = parse_month(params["month"])

    {:noreply,
     socket
     |> assign(selected_month: selected_month, month: month, page: parse_page(params["page"]))
     |> load()}
  end

  @impl true
  def handle_event("filter", %{"month" => month}, socket) do
    params = if parse_month(month) == {nil, nil}, do: [], else: [month: month]
    {:noreply, push_patch(socket, to: ~p"/transactions?#{params}")}
  end

  # line items show product titles, photos and links, and the reset replaces every sale
  @impl true
  def handle_info({event, _product}, socket)
      when event in [:product_created, :product_updated, :product_deleted],
      do: {:noreply, load(socket)}

  def handle_info(:demo_reset, socket), do: {:noreply, load(socket)}
  def handle_info({:transaction_created, _transaction}, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    %{month: month, page: page} = socket.assigns
    result = Transactions.page_transactions(month, page, @per_page)
    months = result.entries |> Enum.map(&month_of([&1])) |> Enum.uniq()

    assign(socket,
      this_month: Date.utc_today() |> Date.beginning_of_month(),
      result: result,
      groups: Enum.chunk_by(result.entries, &month_of([&1])),
      month_totals: Transactions.month_totals(months)
    )
  end

  # a positive page number; anything else is the first page
  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {page, ""} when page >= 1 -> page
      _ -> 1
    end
  end

  defp parse_page(_page), do: 1
end
