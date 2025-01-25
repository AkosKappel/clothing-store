defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end

  def transactions(conn, params) do
    month = params["month"]

    transactions =
      if month do
        [year, month] = String.split(month, "-")
        start_date = Date.new!(String.to_integer(year), String.to_integer(month), 1)
        end_date = Date.end_of_month(start_date)

        start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
        end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

        ClothingStore.Transactions.list_transactions_by_date_range(start_datetime, end_datetime)
      else
        ClothingStore.Transactions.list_transactions()
      end

    render(conn, :transactions, transactions: transactions, selected_month: month)
  end

  def statistics(conn, _params) do
    render(conn, :statistics)
  end
end
