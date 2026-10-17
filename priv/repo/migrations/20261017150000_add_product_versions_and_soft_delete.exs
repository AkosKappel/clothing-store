defmodule ClothingStore.Repo.Migrations.AddProductVersionsAndSoftDelete do
  use Ecto.Migration

  def change do
    # deleted products stay restorable for a few minutes, then they are purged
    alter table(:products) do
      add :deleted_at, :utc_datetime
    end

    create index(:products, [:deleted_at])

    create table(:product_versions) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :snapshot, :map, null: false
      add :changes, :map, null: false, default: %{}
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:product_versions, [:product_id, :inserted_at])
  end
end
