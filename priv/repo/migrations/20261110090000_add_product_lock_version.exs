defmodule ClothingStore.Repo.Migrations.AddProductLockVersion do
  use Ecto.Migration

  def change do
    # bumped by every write to a product, so a form saved over a newer version is refused
    alter table(:products) do
      add :lock_version, :integer, default: 1, null: false
    end
  end
end
