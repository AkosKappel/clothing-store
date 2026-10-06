defmodule ClothingStoreWeb.ProductFormLiveTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  setup :register_and_log_in_user

  @valid %{
    title: "Linen shirt",
    description: "Light and breezy",
    category: "Shirts",
    photo: "/images/products/t-shirt.webp",
    price: "39.90",
    stock: "12",
    tags: "summer, linen"
  }

  test "validates while typing and counts characters", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/products/new")

    html = lv |> form("#product-form", product: %{title: "Linen"}) |> render_change()
    assert html =~ "5/100"

    html = lv |> form("#product-form", product: %{title: ""}) |> render_change()
    assert html =~ "can&#39;t be blank"
    refute html =~ "couldn&#39;t be saved"
  end

  test "a valid new product is posted to the controller and saved", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/products/new")

    form = form(lv, "#product-form", product: @valid)
    assert render_submit(form) =~ ~s(phx-trigger-action)

    conn = follow_trigger_action(form, conn)
    assert %{id: id} = redirected_params(conn)

    product = ClothingStore.Products.get_product!(id)
    assert product.title == "Linen shirt"
    assert product.tags == ["summer", "linen"]
  end

  test "an invalid submit shows the error summary and does not post", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/products/new")

    html =
      lv
      |> form("#product-form", product: %{@valid | photo: "http://x.test/a.png"})
      |> render_submit()

    assert html =~ "couldn&#39;t be saved"
    assert html =~ "must be a path under /images/"
    refute html =~ ~s(phx-trigger-action)
  end

  test "editing shows the current tags and keeps the product's URL", %{conn: conn} do
    product = product_fixture(%{tags: ["summer", "sale"]})
    {:ok, lv, html} = live(conn, ~p"/products/#{product}/edit")

    assert html =~ ~s(value="summer, sale")
    assert has_element?(lv, ~s|#product-form[action="/products/#{product.id}"]|)
    assert has_element?(lv, ~s|#product-form input[name="_method"][value="put"]|)
  end
end
