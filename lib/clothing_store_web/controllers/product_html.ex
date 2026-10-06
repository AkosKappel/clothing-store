defmodule ClothingStoreWeb.ProductHTML do
  use ClothingStoreWeb, :html
  import ClothingStoreWeb.Helpers

  embed_templates "product_html/*"

  @doc """
  Renders a product form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :cancel_to, :string, required: true

  def product_form(assigns)

  @doc "Whether any inventory filter is set."
  def filtered?(filters) do
    Enum.any?(filters, fn {_key, value} -> value not in [nil, "", [], "All"] end)
  end

  @doc "Stock as text, with an explicit out-of-stock state."
  def stock_text(0), do: "Out of stock"
  def stock_text(stock), do: "#{stock} in stock"
end
