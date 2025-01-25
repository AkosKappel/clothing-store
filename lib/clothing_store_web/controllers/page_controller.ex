defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/products")
  end

  def transactions(conn, params) do
    month = params["month"]

    transactions =
      if month && month != "" do
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
    this_month = Date.utc_today() |> Date.to_string()
    last_month = Date.utc_today() |> Date.add(-1 * Date.days_in_month(Date.utc_today())) |> Date.to_string()

    bestsellers = ClothingStore.Transactions.list_bestsellers(3)
    this_month_bestsellers = ClothingStore.Transactions.list_bestsellers_per_month(3, this_month)
    last_month_bestsellers = ClothingStore.Transactions.list_bestsellers_per_month(3, last_month)

    IO.inspect(bestsellers, label: "bestsellers")
    IO.inspect(this_month_bestsellers, label: "this_month_bestsellers")
    IO.inspect(last_month_bestsellers, label: "last_month_bestsellers")

    render(conn, :statistics, bestsellers: bestsellers, this_month_bestsellers: this_month_bestsellers, last_month_bestsellers: last_month_bestsellers)
  end
end
