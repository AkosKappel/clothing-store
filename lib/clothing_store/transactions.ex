defmodule ClothingStore.Transactions do
  @moduledoc "Sales: transactions, their line items and the figures built from them."

  import Ecto.Query, warn: false
  alias ClothingStore.Repo

  alias ClothingStore.Products.ProductTransaction
  alias ClothingStore.Transactions.Transaction

  @doc """
  One page of transactions, newest first, with their line items and products.
  `month` (the first day of a month) limits them to that month; `nil` means all.
  The page is clamped to the existing pages.

  Returns the entries plus the count and revenue of everything that matches.
  """
  def page_transactions(month, page, per_page) do
    query = in_month(Transaction, month)
    total_entries = Repo.aggregate(query, :count)
    total_pages = max(ceil(total_entries / per_page), 1)
    page = page |> max(1) |> min(total_pages)

    entries =
      query
      |> order_by([t], desc: t.inserted_at, desc: t.id)
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> preload(products_transactions: :product)
      |> Repo.all()

    %{
      entries: entries,
      page: page,
      total_pages: total_pages,
      total_entries: total_entries,
      revenue: Repo.aggregate(query, :sum, :total_price) || Decimal.new(0)
    }
  end

  defp in_month(query, nil), do: query

  defp in_month(query, %Date{} = month) do
    from = DateTime.new!(Date.beginning_of_month(month), ~T[00:00:00], "Etc/UTC")
    to = DateTime.new!(month |> Date.end_of_month() |> Date.add(1), ~T[00:00:00], "Etc/UTC")
    where(query, [t], t.inserted_at >= ^from and t.inserted_at < ^to)
  end

  @doc "Sales count and revenue for each of `months` (first days of months) that had sales."
  def month_totals([]), do: %{}

  def month_totals(months) do
    {first, last} = Enum.min_max_by(months, &Date.to_gregorian_days/1)
    from = DateTime.new!(first, ~T[00:00:00], "Etc/UTC")
    to = DateTime.new!(last |> Date.end_of_month() |> Date.add(1), ~T[00:00:00], "Etc/UTC")

    from(t in Transaction,
      where: t.inserted_at >= ^from and t.inserted_at < ^to,
      group_by: fragment("date_trunc('month', ?)", t.inserted_at),
      select: {
        fragment("date_trunc('month', ?)::date", t.inserted_at),
        %{revenue: sum(t.total_price), count: count(t.id)}
      }
    )
    |> Repo.all()
    |> Map.new()
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
  Revenue per product category since `since`, largest first, at the prices
  the products sold for.
  """
  def revenue_by_category(%DateTime{} = since) do
    from(pt in ProductTransaction,
      join: t in assoc(pt, :transaction),
      join: p in assoc(pt, :product),
      where: t.inserted_at >= ^since,
      group_by: p.category,
      select: {p.category, sum(fragment("? * ?", pt.quantity, pt.unit_price))},
      order_by: [desc: sum(fragment("? * ?", pt.quantity, pt.unit_price))]
    )
    |> Repo.all()
  end
end
