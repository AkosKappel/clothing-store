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

  test "the list view is kept in the URL", %{conn: conn} do
    product = product_fixture(%{title: "Linen shirt"})
    {:ok, lv, _html} = live(conn, ~p"/")

    lv |> element(~s(a[role=button]), "List") |> render_click()
    assert_patch(lv, ~p"/?view=list")
    assert has_element?(lv, ~s(a[aria-pressed=true]), "List")
    assert has_element?(lv, "#product-#{product.id} img.size-12")
  end

  test "products load 24 at a time", %{conn: conn} do
    for n <- 1..30, do: product_fixture(%{title: "Product #{n}"})
    {:ok, lv, _html} = live(conn, ~p"/")

    assert lv |> render() |> count_products() == 24
    assert has_element?(lv, "button", "Load more")

    lv |> element("button", "Load more") |> render_click()
    assert lv |> render() |> count_products() == 30
    refute has_element?(lv, "button", "Load more")
  end

  defp count_products(html), do: length(Regex.scan(~r/id="product-\d+"/, html))
end
