defmodule ClothingStore.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :title, :string
    field :category, :string
    field :photo, :string
    field :price, :decimal
    field :stock, :integer
    field :tags, {:array, :string}, default: []

    has_many :products_transactions, ClothingStore.Products.ProductTransaction
    has_many :transactions, through: [:products_transactions, :transaction]

    timestamps(type: :utc_datetime)
  end

  @max_amount 100_000
  @max_tags 10
  @max_tag_length 30

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:photo, :title, :description, :category, :price, :stock, :tags])
    |> validate_required([:photo, :title, :description, :category, :price, :stock])
    |> validate_length(:title, max: 100)
    |> validate_length(:category, max: 50)
    |> validate_length(:description, max: 2000)
    |> validate_length(:photo, max: 500)
    |> validate_tags()
    |> validate_number(:price, greater_than_or_equal_to: 0, less_than_or_equal_to: @max_amount)
    |> validate_number(:stock, greater_than_or_equal_to: 0, less_than_or_equal_to: @max_amount)
  end

  defp validate_tags(changeset) do
    validate_change(changeset, :tags, fn :tags, tags ->
      cond do
        length(tags) > @max_tags ->
          [tags: "should have at most #{@max_tags} tags"]

        Enum.any?(tags, &(String.length(&1) not in 1..@max_tag_length)) ->
          [tags: "each tag should be 1 to #{@max_tag_length} characters"]

        true ->
          []
      end
    end)
  end
end
