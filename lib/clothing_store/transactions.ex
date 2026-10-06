defmodule ClothingStore.Transactions do
  import Ecto.Query, warn: false
  alias ClothingStore.Repo

  alias ClothingStore.Products.ProductTransaction
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

  @doc """
  Revenue and number of transactions for each of the last `months` calendar
  months (UTC), oldest first, including the current month. Months without
  sales are included with zeros.
  """
  def monthly_sales(months \\ 12, today \\ Date.utc_today()) do
    first = today |> Date.beginning_of_month() |> Date.shift(month: -(months - 1))
    since = DateTime.new!(first, ~T[00:00:00], "Etc/UTC")

    totals =
      from(t in Transaction,
        where: t.inserted_at >= ^since,
        group_by: fragment("date_trunc('month', ?)", t.inserted_at),
        select: {
          fragment("date_trunc('month', ?)::date", t.inserted_at),
          sum(t.total_price),
          count(t.id)
        }
      )
      |> Repo.all()
      |> Map.new(fn {month, revenue, count} -> {month, {revenue, count}} end)

    for offset <- 0..(months - 1) do
      month = Date.shift(first, month: offset)
      {revenue, count} = Map.get(totals, month, {Decimal.new(0), 0})
      %{month: month, revenue: revenue, count: count}
    end
  end

  @doc """
  Revenue per product category since `since`, largest first. Line items are
  valued at the product's current price.
  """
  def revenue_by_category(%DateTime{} = since) do
    from(pt in ProductTransaction,
      join: t in assoc(pt, :transaction),
      join: p in assoc(pt, :product),
      where: t.inserted_at >= ^since,
      group_by: p.category,
      select: {p.category, sum(fragment("? * ?", pt.quantity, p.price))},
      order_by: [desc: sum(fragment("? * ?", pt.quantity, p.price))]
    )
    |> Repo.all()
  end
end
