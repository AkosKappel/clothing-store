defmodule ClothingStore.TransactionsTest do
  use ClothingStore.DataCase, async: true

  import ClothingStore.ProductsFixtures
  import ClothingStore.TransactionsFixtures

  alias ClothingStore.{Products, Transactions}

  @today ~D[2026-10-06]

  test "monthly_sales/2 lists every month in the window, oldest first, with zeros for quiet months" do
    shirt = product_fixture(%{price: "20.00"})
    sale_fixture([{shirt, 2}], ~U[2026-10-01 08:00:00Z])
    sale_fixture([{shirt, 1}], ~U[2026-10-05 18:00:00Z])
    sale_fixture([{shirt, 1}], ~U[2026-08-31 23:59:59Z])
    # before the window
    sale_fixture([{shirt, 5}], ~U[2026-07-31 23:59:59Z])

    assert [aug, sep, oct] = Transactions.monthly_sales(3, @today)

    assert aug.month == ~D[2026-08-01] and aug.count == 1
    assert Decimal.equal?(aug.revenue, 20)
    assert sep.month == ~D[2026-09-01] and sep.count == 0
    assert Decimal.equal?(sep.revenue, 0)
    assert oct.count == 2
    assert Decimal.equal?(oct.revenue, 60)
  end

  test "revenue_by_category/1 sums line items per category, largest first" do
    shirt = product_fixture(%{category: "Shirts & Tops", price: "20.00"})
    shoe = product_fixture(%{category: "Shoes", price: "100.00"})
    sale_fixture([{shirt, 3}, {shoe, 1}], ~U[2026-10-02 10:00:00Z])
    sale_fixture([{shoe, 5}], ~U[2025-01-01 10:00:00Z])

    assert [{"Shoes", shoes}, {"Shirts & Tops", shirts}] =
             Transactions.revenue_by_category(~U[2026-01-01 00:00:00Z])

    assert Decimal.equal?(shoes, 100)
    assert Decimal.equal?(shirts, 60)
  end

  test "Products.stock_alerts/0 counts sold-out and low products separately" do
    for stock <- [0, 0, 1, 5, 6, 40], do: product_fixture(%{stock: stock})

    assert Products.stock_alerts() == %{out: 2, low: 2}
  end
end
