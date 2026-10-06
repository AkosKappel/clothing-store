defmodule ClothingStore.TransactionsFixtures do
  @moduledoc "Test helpers for recording sales."

  alias ClothingStore.Products.ProductTransaction
  alias ClothingStore.Repo
  alias ClothingStore.Transactions.Transaction

  @doc "Records a sale of `[{product, quantity}]` at `at`, totalled at current prices."
  def sale_fixture(items, at \\ DateTime.utc_now(:second)) do
    total =
      Enum.reduce(items, Decimal.new(0), fn {product, quantity}, sum ->
        Decimal.add(sum, Decimal.mult(product.price, quantity))
      end)

    transaction = Repo.insert!(%Transaction{total_price: total, inserted_at: at, updated_at: at})

    for {product, quantity} <- items do
      Repo.insert!(%ProductTransaction{
        product_id: product.id,
        transaction_id: transaction.id,
        quantity: quantity,
        unit_price: product.price
      })
    end

    transaction
  end
end
