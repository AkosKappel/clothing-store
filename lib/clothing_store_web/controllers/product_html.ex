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
            {"category", &"Category: #{&1}"},
            {"min_price", &"From #{&1} €"},
            {"max_price", &"Up to #{&1} €"},
            {"in_stock", fn _ -> "In stock" end}
          ],
          value = params[key],
          value != nil,
          do: {label.(value), Map.delete(params, key)}

    tags =
      for tag <- params["tags"] || [],
          do: {"##{tag}", Map.update!(params, "tags", &List.delete(&1, tag))}

    single ++ tags
  end

  defp blank?(value),
    do: value in [nil, "", [], "All"] or (is_binary(value) and String.trim(value) == "")
end
