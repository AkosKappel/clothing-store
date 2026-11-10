defmodule ClothingStore.Repo.Migrations.AddUserRoles do
  use Ecto.Migration

  def change do
    # "demo" for the shared demo account, "admin" for the private owner account
    alter table(:users) do
      add :role, :string, default: "demo", null: false
    end
  end
end
