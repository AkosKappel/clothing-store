defmodule ClothingStore.Repo.Migrations.CreateProductsTransactions do
  use Ecto.Migration

  def change do
    create table(:products_transactions) do
      add :quantity, :integer

      add :product_id, references(:products, on_delete: :delete_all)
      add :transaction_id, references(:transactions, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products_transactions, [:product_id, :transaction_id])
  end
end
