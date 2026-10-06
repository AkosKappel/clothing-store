defmodule ClothingStore.Repo.Migrations.AddUnitPriceToProductsTransactions do
  use Ecto.Migration

  # The price a product sold for, so later price changes don't rewrite past sales.
  def up do
    alter table(:products_transactions) do
      add :unit_price, :decimal
    end

    execute """
    UPDATE products_transactions AS pt
    SET unit_price = p.price
    FROM products AS p
    WHERE p.id = pt.product_id
    """

    alter table(:products_transactions) do
      modify :unit_price, :decimal, null: false
    end
  end

  def down do
    alter table(:products_transactions) do
      remove :unit_price
    end
  end
end
