defmodule ClothingStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :photo, :string
      add :title, :string
      add :description, :text
      add :category, :string
      add :price, :decimal
      add :stock, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
