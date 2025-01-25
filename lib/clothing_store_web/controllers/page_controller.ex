defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end

  def transactions(conn, _params) do
    transactions = ClothingStore.Transactions.list_transactions()

    # print each transaction and a list of its product IDs
    for transaction <- transactions do
      IO.puts("Transaction ID: #{transaction.id} Created At: #{transaction.inserted_at} Total Price: #{transaction.total_price}")
      for product_transaction <- transaction.products_transactions do
        product = product_transaction.product
        IO.puts("  Product-Transaction ID: #{product_transaction.id} Product ID: #{product.id} Name: #{product.title} Transaction ID: #{product_transaction.transaction_id} Quantity: #{product_transaction.quantity}")
      end
    end

    render(conn, :transactions, transactions: transactions)
  end

  def statistics(conn, _params) do
    render(conn, :statistics)
  end
end
