defmodule ClothingStoreWeb.InventoryLiveTest do
  # not async: the LiveViews listen on the shared "products" topic
  use ClothingStoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  alias ClothingStore.Products

  setup :register_and_log_in_user

  test "the inventory refreshes when a product changes elsewhere", %{conn: conn} do
    product = product_fixture(%{title: "Linen shirt", stock: 40})
    {:ok, lv, _html} = live(conn, ~p"/products")

    {:ok, _} = Products.update_product(product, %{title: "Linen shirt (blue)"})
    assert render(lv) =~ "Linen shirt (blue)"

    {:ok, _} = Products.delete_product(Products.get_product!(product.id))
    refute render(lv) =~ "Linen shirt"
  end

  test "filtering patches the URL instead of reloading", %{conn: conn} do
    product_fixture(%{title: "Linen shirt"})
    product_fixture(%{title: "Wool coat"})
    {:ok, lv, _html} = live(conn, ~p"/products")

    lv |> form("#filters-form", %{"q" => "wool"}) |> render_change()

    assert_patch(lv, ~p"/products?q=wool")
    assert has_element?(lv, "#products", "Wool coat")
    refute has_element?(lv, "#products", "Linen shirt")
  end

  test "the product page follows edits and leaves when the product is deleted", %{conn: conn} do
    product = product_fixture(%{title: "Linen shirt"})
    {:ok, lv, _html} = live(conn, ~p"/products/#{product}")

    {:ok, _} = Products.update_product(product, %{title: "Linen shirt (blue)"})
    assert render(lv) =~ "Linen shirt (blue)"

    {:ok, _} = Products.delete_product(Products.get_product!(product.id))
    assert_redirect(lv, ~p"/")
  end

  test "the nav links navigate without a page load", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/")

    assert {:ok, _lv, html} =
             lv |> element("#menu a", "Inventory") |> render_click() |> follow_redirect(conn)

    assert html =~ "Every product with its stock"
  end

  test "a product opens in a drawer that follows live changes and closes to the list", %{
    conn: conn
  } do
    product = product_fixture(%{title: "Linen shirt"})
    {:ok, lv, _html} = live(conn, ~p"/products?q=linen")

    lv |> element("#products a[aria-haspopup]", "Linen shirt") |> render_click()
    assert_patch(lv, ~p"/products?product=#{product.id}&q=linen")
    assert has_element?(lv, "#product-drawer-title", "Linen shirt")
    assert has_element?(lv, "#product-drawer a[href='/products/#{product.id}']", "Open full page")

    {:ok, _} = Products.update_product(product, %{title: "Linen shirt (blue)"})
    assert has_element?(lv, "#product-drawer-title", "Linen shirt (blue)")

    lv |> element("#product-drawer [data-drawer-close]") |> render_click()
    assert_patch(lv, ~p"/products?q=linen")
    refute has_element?(lv, "#product-drawer")
  end

  test "a drawer link to a missing product shows just the list", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/products?product=999999")
    refute has_element?(lv, "#product-drawer")
  end

  test "the product page links back to the dashboard", %{conn: conn} do
    product = product_fixture()
    {:ok, lv, _html} = live(conn, ~p"/products/#{product}")
    assert has_element?(lv, "main a[href='/']", "Dashboard")
  end
end
