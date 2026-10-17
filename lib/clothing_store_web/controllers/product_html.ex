defmodule ClothingStoreWeb.ProductHTML do
  use ClothingStoreWeb, :html
  import ClothingStoreWeb.Helpers

  embed_templates "product_html/*"

  @doc "Whether any inventory filter is set (sorting is not a filter)."
  def filtered?(filters) do
    Enum.any?(Map.delete(filters, "sort"), fn {_key, value} -> blank?(value) == false end)
  end

  @doc """
  One `{label, params}` chip per active filter; `params` are the inventory
  query params without that filter, so following the chip removes it.
  """
  def filter_chips(filters) do
    params = filters |> Enum.reject(fn {_key, value} -> blank?(value) end) |> Map.new()

    single =
      for {key, label} <- [
            {"q", &"“#{&1}”"},
            {"category", &gettext("Category: %{category}", category: &1)},
            {"min_price", &gettext("From %{price} €", price: &1)},
            {"max_price", &gettext("Up to %{price} €", price: &1)},
            {"in_stock", fn _ -> gettext("In stock") end},
            {"low_stock", fn _ -> gettext("Low stock") end}
          ],
          value = params[key],
          value != nil,
          do: {label.(value), Map.delete(params, key)}

    tags =
      for tag <- params["tags"] || [],
          do: {"##{tag}", Map.update!(params, "tags", &List.delete(&1, tag))}

    single ++ tags
  end

  @doc "The active filters and sort as query params, for the CSV export link."
  def export_params(filters), do: Enum.reject(filters, fn {_key, value} -> blank?(value) end)

  @doc "A heading for one entry of a product's history."
  def version_title("created"), do: gettext("Added to the catalogue")
  def version_title("updated"), do: gettext("Edited")
  def version_title("restocked"), do: gettext("Restocked")
  def version_title("restored"), do: gettext("Restored after a delete")
  def version_title(action), do: String.capitalize(action)

  defp blank?(value),
    do: value in [nil, "", [], "All"] or (is_binary(value) and String.trim(value) == "")

  @doc "The inventory sort options as `{label, value}`; the first is the default."
  def sort_options do
    [
      {gettext("Newest first"), "newest"},
      {gettext("Price: low to high"), "price_asc"},
      {gettext("Price: high to low"), "price_desc"},
      {gettext("Stock: low to high"), "stock_asc"},
      {gettext("Stock: high to low"), "stock_desc"},
      {gettext("Name: A to Z"), "title"}
    ]
  end
end
