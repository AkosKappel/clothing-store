defmodule ClothingStore.Transactions do
  import Ecto.Query, warn: false
  alias ClothingStore.Repo

  alias ClothingStore.Transactions.Transaction

  def list_transactions do
    Repo.all(Transaction)
    |> Repo.preload(products_transactions: [:product])
  end

  @doc """
  Returns transactions within the specified date range.
  """
  def list_transactions_by_date_range(start_date, end_date) do
    Transaction
    |> where([t], t.inserted_at >= ^start_date and t.inserted_at <= ^end_date)
    |> preload(products_transactions: [:product])
    |> Repo.all()
  end
end
