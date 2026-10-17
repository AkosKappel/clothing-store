defmodule ClothingStore.Repo.Migrations.AddQueryIndexes do
  use Ecto.Migration

  # product_id lookups already use the unique (product_id, transaction_id) index
  def change do
    create index(:transactions, [:inserted_at])
    create index(:products_transactions, [:transaction_id])
    create index(:products, [:category])
    # the tag filter uses the && (overlap) operator
    create index(:products, [:tags], using: :gin)
  end
end
