defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.{About, Demo, Transactions}

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

  def transactions(conn, params) do
    {month, start_date} = parse_month(params["month"])

    transactions =
      if start_date do
        end_date = Date.end_of_month(start_date)

        start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
        end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

        Transactions.list_transactions_by_date_range(start_datetime, end_datetime)
      else
        Transactions.list_transactions()
      end

    render(conn, :transactions,
      page_title: "Transactions",
      transactions: transactions,
      selected_month: month,
      month_label: start_date && Calendar.strftime(start_date, "%B %Y"),
      revenue:
        transactions |> Enum.map(& &1.total_price) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    )
  end

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

    render(conn, :statistics,
      page_title: "Statistics",
      this_month: this_month,
      last_month: last_month,
      bestsellers: Transactions.list_bestsellers(3),
      this_month_bestsellers:
        Transactions.list_bestsellers_per_month(3, Date.to_string(this_month)),
      last_month_bestsellers:
        Transactions.list_bestsellers_per_month(3, Date.to_string(last_month))
    )
  end
end
