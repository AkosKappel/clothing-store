defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.{About, Demo, Products, Transactions}

  def about(conn, _params) do
    links = Demo.links()

    render(conn, :about,
      page_title: "About",
      author: Demo.author(),
      links: links,
      repository: links[:repository],
      reset: Demo.reset_settings(),
      photo_sources: About.photo_sources(),
      stack: About.stack()
    )
  end

  @per_page 20

  def transactions(conn, params) do
    {selected_month, month} = parse_month(params["month"])
    result = Transactions.page_transactions(month, parse_page(params["page"]), @per_page)
    months = result.entries |> Enum.map(&month_of/1) |> Enum.uniq()

    render(conn, :transactions,
      page_title: "Transactions",
      selected_month: selected_month,
      month: month,
      this_month: Date.utc_today() |> Date.beginning_of_month(),
      result: result,
      per_page: @per_page,
      groups: Enum.chunk_by(result.entries, &month_of/1),
      month_totals: Transactions.month_totals(months)
    )
  end

  defp month_of(transaction),
    do: transaction.inserted_at |> DateTime.to_date() |> Date.beginning_of_month()

  # a positive page number; anything else is the first page
  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {page, ""} when page >= 1 -> page
      _ -> 1
    end
  end

  defp parse_page(_page), do: 1

  # "YYYY-MM"; anything else shows every transaction
  defp parse_month(month) when is_binary(month) do
    with true <- Regex.match?(~r/^\d{4}-\d{2}$/, month),
         {:ok, date} <- Date.from_iso8601(month <> "-01") do
      {month, date}
    else
      _ -> {nil, nil}
    end
  end

  defp parse_month(_month), do: {nil, nil}

  def statistics(conn, _params) do
    this_month = Date.utc_today() |> Date.beginning_of_month()
    last_month = this_month |> Date.add(-1) |> Date.beginning_of_month()
    monthly = Transactions.monthly_sales(12)
    since = monthly |> hd() |> Map.fetch!(:month) |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    render(conn, :statistics,
      page_title: "Statistics",
      this_month: this_month,
      last_month: last_month,
      monthly: monthly,
      categories: Transactions.revenue_by_category(since),
      stock_alerts: Products.stock_alerts(),
      bestsellers: Transactions.list_bestsellers(3),
      this_month_bestsellers:
        Transactions.list_bestsellers_per_month(3, Date.to_string(this_month)),
      last_month_bestsellers:
        Transactions.list_bestsellers_per_month(3, Date.to_string(last_month))
    )
  end
end
