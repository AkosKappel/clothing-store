defmodule ClothingStore.Products.Version do
  @moduledoc """
  A product as it was after one change. `action` is `created`, `updated`,
  `restocked` or `restored`; `snapshot` holds the product's fields after the change
  and `changes` the `{field => [old, new]}` pairs of that change.
  """
  use Ecto.Schema

  schema "product_versions" do
    field :product_id, :id
    field :action, :string
    field :snapshot, :map
    field :changes, :map, default: %{}
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
