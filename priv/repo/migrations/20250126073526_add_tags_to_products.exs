defmodule ClothingStore.Repo.Migrations.AddTagsToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :tags, {:array, :string}, default: []
    end
  end
end
