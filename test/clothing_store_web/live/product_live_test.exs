defmodule ClothingStoreWeb.ProductLiveTest do
  # not async: other tests broadcast on the shared "products" topic this LiveView listens to
  use ClothingStoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  setup :register_and_log_in_user

  test "a product changed elsewhere is highlighted, announced, then unhighlighted", %{conn: conn} do
    product = product_fixture(%{title: "Linen shirt"})
    {:ok, lv, _html} = live(conn, ~p"/")

    refute has_element?(lv, "#product-#{product.id} .live-highlight")

    send(lv.pid, {:product_updated, %{product | stock: 3}})

    assert has_element?(lv, "#product-#{product.id} .live-highlight")
    assert has_element?(lv, "#product-#{product.id}", "Low: 3 left")
    assert has_element?(lv, "#live-announcement", "Linen shirt was updated")

    send(lv.pid, {:unhighlight, product.id})
    refute has_element?(lv, "#product-#{product.id} .live-highlight")
  end

  test "a product deleted elsewhere disappears and is announced", %{conn: conn} do
    product = product_fixture(%{title: "Linen shirt"})
    {:ok, lv, _html} = live(conn, ~p"/")

    send(lv.pid, {:product_deleted, product})

    refute has_element?(lv, "#product-#{product.id}")
    assert has_element?(lv, "#live-announcement", "Linen shirt was deleted")
  end

  test "a demo reset reloads the products", %{conn: conn} do
    product = product_fixture(%{title: "Linen shirt"})
    {:ok, lv, _html} = live(conn, ~p"/")

    {:ok, _} = ClothingStore.Products.delete_product(product)
    # the delete broadcast already removed it; put it back to see the reload drop it
    send(lv.pid, {:product_created, product})
    assert has_element?(lv, "#product-#{product.id}")

    send(lv.pid, :demo_reset)
    refute has_element?(lv, "#product-#{product.id}")
  end
end
