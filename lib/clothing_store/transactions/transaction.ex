defmodule ClothingStore.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :total_price, :decimal

    has_many :products_transactions, ClothingStore.Products.ProductTransaction
    has_many :products, through: [:products_transactions, :product]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:total_price])
    |> validate_required([:total_price])
  end
end
