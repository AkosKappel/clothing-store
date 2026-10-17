defmodule ClothingStore.Demo.ActivityTest do
  use ClothingStore.DataCase, async: false

  import ClothingStore.ProductsFixtures

  alias ClothingStore.Demo.Activity
  alias ClothingStore.{Products, Transactions}

  describe "Transactions.record_sale/1" do
    test "records the sale at current prices, takes the stock and broadcasts" do
      shirt = product_fixture(price: "20.00", stock: 5)
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "transactions")

      assert {:ok, transaction} = Transactions.record_sale([{shirt, 2}])
      assert Decimal.equal?(transaction.total_price, "40.00")
      assert Products.get_product!(shirt.id).stock == 3
      assert_receive {:product_updated, %{id: id, stock: 3}} when id == shirt.id
      assert_receive {:transaction_created, %{id: tid}} when tid == transaction.id
    end

    test "sells nothing when one product is short" do
      plenty = product_fixture(stock: 5)
      short = product_fixture(stock: 1)

      assert {:error, :out_of_stock} = Transactions.record_sale([{plenty, 1}, {short, 2}])
      assert Products.get_product!(plenty.id).stock == 5
      assert Transactions.count_today() == 0
    end
  end

  describe "simulate/1" do
    test "sells from in-stock products only" do
      product = product_fixture(stock: 3)
      product_fixture(stock: 0)

      assert %{sale: {:ok, _}} = Activity.simulate(10)
      assert Products.get_product!(product.id).stock in 1..2
      assert Transactions.count_today() == 1
    end

    test "stops selling at the daily limit" do
      product_fixture(stock: 3)
      assert %{sale: nil} = Activity.simulate(0)
    end
  end
end
