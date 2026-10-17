defmodule ClothingStore.Repo.Migrations.CreateProductVariants do
  use Ecto.Migration

  def change do
    create table(:product_variants) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :size, :string, null: false
      add :colour, :string
      add :stock, :integer, null: false, default: 0
      timestamps(type: :utc_datetime)
    end

    create unique_index(:product_variants, [:product_id, :size, :colour], nulls_distinct: false)
  end
end
