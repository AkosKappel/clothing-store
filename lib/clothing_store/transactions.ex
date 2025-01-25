defmodule ClothingStore.Transactions do
  import Ecto.Query, warn: false
  alias ClothingStore.Repo

  alias ClothingStore.Transactions.Transaction

  def list_transactions do
    Repo.all(Transaction)
    |> Repo.preload(products_transactions: [:product])
  end
end
