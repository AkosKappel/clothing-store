defmodule ClothingStoreWeb.ProductComponents do
  @moduledoc "Badges for product data shared by the dashboard, inventory and statistics pages."
  use Phoenix.Component

  import ClothingStoreWeb.CoreComponents, only: [badge: 1]

  @low_stock 5

  # literal class strings so Tailwind can see them
  @category_colors [
    "bg-sky-50 text-sky-800 ring-sky-600/20",
    "bg-violet-50 text-violet-800 ring-violet-600/20",
    "bg-amber-50 text-amber-800 ring-amber-600/20",
    "bg-teal-50 text-teal-800 ring-teal-600/20",
    "bg-pink-50 text-pink-800 ring-pink-600/20",
    "bg-indigo-50 text-indigo-800 ring-indigo-600/20"
  ]

  @doc "Stock as a coloured badge: in stock, low (#{@low_stock} or fewer) or out of stock."
  attr :stock, :integer, required: true

  def stock_badge(assigns) do
    ~H"""
    <.badge class={stock_class(@stock)}>{stock_text(@stock)}</.badge>
    """
  end

  @doc "A category badge whose colour is stable for the same category name."
  attr :category, :string, required: true

  def category_badge(assigns) do
    ~H"""
    <.badge class={category_class(@category)}>{@category}</.badge>
    """
  end

  def stock_text(0), do: "Out of stock"
  def stock_text(stock) when stock <= @low_stock, do: "Low: #{stock} left"
  def stock_text(stock), do: "#{stock} in stock"

  defp stock_class(0), do: "bg-red-50 text-red-800 ring-red-600/20"

  defp stock_class(stock) when stock <= @low_stock,
    do: "bg-amber-50 text-amber-800 ring-amber-600/20"

  defp stock_class(_stock), do: "bg-emerald-50 text-emerald-800 ring-emerald-600/20"

  defp category_class(category),
    do: Enum.at(@category_colors, :erlang.phash2(category, length(@category_colors)))
end
