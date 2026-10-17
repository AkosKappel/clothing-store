defmodule ClothingStore.Repo.Migrations.CreateActivityEvents do
  use Ecto.Migration

  def change do
    create table(:activity_events) do
      add :kind, :string, null: false
      add :product_id, references(:products, on_delete: :nilify_all)
      add :product_title, :string
      add :data, :map, null: false, default: %{}
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:activity_events, [:inserted_at])
  end
end
