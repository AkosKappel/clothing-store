defmodule ClothingStore.Repo.Migrations.AddDiscounts do
  use Ecto.Migration

  def change do
    # a scheduled discount: percent off from one date to another (both inclusive, UTC)
    alter table(:products) do
      add :discount_percent, :integer
      add :discount_starts_on, :date
      add :discount_ends_on, :date
    end

    # the list price at the time of the sale; unit_price is what the customer paid
    alter table(:products_transactions) do
      add :full_price, :decimal
    end

    execute "UPDATE products_transactions SET full_price = unit_price", ""
  end
end
