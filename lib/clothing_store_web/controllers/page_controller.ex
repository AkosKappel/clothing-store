defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.{About, Demo}

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

        ClothingStore.Transactions.list_transactions_by_date_range(start_datetime, end_datetime)
      else
        ClothingStore.Transactions.list_transactions()
      end

    render(conn, :transactions, transactions: transactions, selected_month: month)
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
    this_month = Date.utc_today() |> Date.to_string()

    last_month =
      Date.utc_today() |> Date.add(-1 * Date.days_in_month(Date.utc_today())) |> Date.to_string()

    bestsellers = ClothingStore.Transactions.list_bestsellers(3)
    this_month_bestsellers = ClothingStore.Transactions.list_bestsellers_per_month(3, this_month)
    last_month_bestsellers = ClothingStore.Transactions.list_bestsellers_per_month(3, last_month)

    render(conn, :statistics,
      bestsellers: bestsellers,
      this_month_bestsellers: this_month_bestsellers,
      last_month_bestsellers: last_month_bestsellers
    )
  end
end
