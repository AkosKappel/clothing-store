defmodule ClothingStoreWeb.ProductHTML do
  use ClothingStoreWeb, :html
  import ClothingStoreWeb.Helpers

  embed_templates "product_html/*"

  @doc "Whether any inventory filter is set."
  def filtered?(filters) do
    Enum.any?(filters, fn {_key, value} -> value not in [nil, "", [], "All"] end)
  end
end
