defmodule ClothingStore.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :quantity, :integer
      add :product_id, references(:products, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
