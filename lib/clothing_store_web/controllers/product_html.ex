defmodule ClothingStoreWeb.ProductHTML do
  use ClothingStoreWeb, :html
  import ClothingStoreWeb.Helpers

  embed_templates "product_html/*"

  @doc """
  Renders a product form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def product_form(assigns)
end
