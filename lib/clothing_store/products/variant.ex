defmodule ClothingStore.Products.Variant do
  @moduledoc "One size (and optionally colour) of a product, with its own stock."
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_variants" do
    field :size, :string
    field :colour, :string
    field :stock, :integer, default: 0
    belongs_to :product, ClothingStore.Products.Product
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [:size, :colour, :stock])
    |> validate_required([:size, :stock])
    |> validate_length(:size, max: 10)
    |> validate_length(:colour, max: 30)
    |> validate_number(:stock, greater_than_or_equal_to: 0, less_than_or_equal_to: 100_000)
    |> unique_constraint([:size, :colour],
      name: :product_variants_product_id_size_colour_index,
      message: "is listed twice"
    )
  end
end
