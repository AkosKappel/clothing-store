defmodule ClothingStore.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :total_price, :decimal

      timestamps(type: :utc_datetime)
    end
  end
end
