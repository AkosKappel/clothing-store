defmodule ClothingStore.Transactions do
  import Ecto.Query, warn: false
  alias ClothingStore.Repo

  alias ClothingStore.Transactions.Transaction

  def list_transactions do
    Transaction
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(products_transactions: [:product])
  end

  @doc """
  Returns transactions within the specified date range.
  """
  def list_transactions_by_date_range(start_date, end_date) do
    Transaction
    |> where([t], t.inserted_at >= ^start_date and t.inserted_at <= ^end_date)
    |> order_by([t], desc: t.inserted_at)
    |> preload(products_transactions: [:product])
    |> Repo.all()
  end

  def list_bestsellers(n) do
    Transaction
    |> join(:inner, [t], pt in assoc(t, :products_transactions))
    |> join(:inner, [t, pt], p in assoc(pt, :product))
    |> group_by([t, pt, p], p.id)
    |> select([t, pt, p], {p, sum(pt.quantity)})
    |> order_by([t, pt, p], desc: sum(pt.quantity))
    |> limit(^n)
    |> Repo.all()
  end

  def list_bestsellers_per_month(n, month) do
    [year, month, _day] = String.split(month, "-")
    start_date = Date.new!(String.to_integer(year), String.to_integer(month), 1)
    end_date = Date.end_of_month(start_date)

    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    Transaction
    |> join(:inner, [t], pt in assoc(t, :products_transactions))
    |> join(:inner, [t, pt], p in assoc(pt, :product))
    |> where([t], t.inserted_at >= ^start_datetime and t.inserted_at <= ^end_datetime)
    |> group_by([t, pt, p], p.id)
    |> select([t, pt, p], {p, sum(pt.quantity)})
    |> order_by([t, pt, p], desc: sum(pt.quantity))
    |> limit(^n)
    |> Repo.all()
  end
end
