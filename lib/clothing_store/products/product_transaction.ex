defmodule ClothingStore.Products.ProductTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products_transactions" do
    field :quantity, :integer

    belongs_to :product, ClothingStore.Products.Product
    belongs_to :transaction, ClothingStore.Transactions.Transaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product_transaction, attrs) do
    product_transaction
    |> cast(attrs, [:quantity, :product_id, :transaction_id])
    |> validate_required([:quantity, :product_id, :transaction_id])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:product_id, :transaction_id], name: "products_transactions_pkey")
  end
end
