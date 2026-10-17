defmodule ClothingStore.DiscountsTest do
  use ClothingStore.DataCase, async: true

  import ClothingStore.ProductsFixtures

  alias ClothingStore.{Products, Transactions}
  alias ClothingStore.Products.Product

  @today Date.utc_today()

  defp discounted(attrs \\ %{}) do
    product_fixture(
      Map.merge(
        %{
          price: "50.00",
          stock: 10,
          discount_percent: 20,
          discount_starts_on: Date.add(@today, -1),
          discount_ends_on: Date.add(@today, 1)
        },
        attrs
      )
    )
  end

  test "the discount applies only between its dates" do
    product = discounted()
    assert Product.on_sale?(product)
    assert Decimal.equal?(Product.sale_price(product), "40.00")
    refute Product.on_sale?(product, Date.add(@today, 2))
    assert Decimal.equal?(Product.sale_price(product, Date.add(@today, -2)), "50.00")
  end

  test "a discount needs dates in order and at most 90 %" do
    errors = fn attrs -> %Product{} |> Product.changeset(attrs) |> errors_on() end

    assert %{discount_starts_on: ["is needed for a discount"]} = errors.(%{discount_percent: 10})
    assert %{discount_percent: [_]} = errors.(%{discount_percent: 95})

    assert %{discount_ends_on: ["can't be before the start"]} =
             errors.(%{
               discount_percent: 10,
               discount_starts_on: @today,
               discount_ends_on: Date.add(@today, -1)
             })
  end

  test "sales use the discounted price and statistics add up the discount" do
    product = discounted()
    {:ok, transaction} = Transactions.record_sale([{product, 2}])

    assert Decimal.equal?(transaction.total_price, "80.00")
    assert Decimal.equal?(Transactions.discounts_given(Date.beginning_of_month(@today)), "20.00")
  end

  test "the price history keeps every price change" do
    product = product_fixture(price: "50.00")
    {:ok, _} = Products.update_product(product, %{price: "45.00"})
    {:ok, _} = Products.update_product(product, %{title: "Renamed"})

    prices =
      product.id |> Products.list_versions() |> Products.price_history() |> Enum.map(&elem(&1, 0))

    assert Enum.map(prices, &Decimal.to_string/1) == ["45.00", "50.00"]
  end
end
