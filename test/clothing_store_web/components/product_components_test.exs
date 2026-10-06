defmodule ClothingStoreWeb.ProductComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ClothingStoreWeb.ProductComponents

  test "stock_badge/1 tells in stock, low and out of stock apart" do
    assert render_component(&stock_badge/1, stock: 0) =~ "Out of stock"
    assert render_component(&stock_badge/1, stock: 5) =~ "Low: 5 left"
    assert render_component(&stock_badge/1, stock: 6) =~ "6 in stock"
  end

  test "category_badge/1 gives a category the same colour every time" do
    html = render_component(&category_badge/1, category: "Shoes")
    assert html =~ "Shoes"
    assert html == render_component(&category_badge/1, category: "Shoes")
  end
end
