defmodule ClothingStoreWeb.ProductFormLiveTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  alias ClothingStore.Products.Photos
  alias Vix.Vips.{Image, Operation}

  setup :register_and_log_in_user

  @valid %{
    title: "Linen shirt",
    description: "Light and breezy",
    category: "Shirts",
    photo: "/images/products/white-t-shirt.webp",
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

  test "previews the photo only once it passes validation", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/products/new")
    refute html =~ "photo-preview"

    html =
      lv
      |> form("#product-form", product: %{photo: "https://evil.example/x.png"})
      |> render_change()

    refute html =~ "photo-preview"

    html = lv |> form("#product-form", product: %{photo: @valid.photo}) |> render_change()
    assert html =~ ~s(id="photo-preview" src="#{@valid.photo}")
  end

  test "tags show as chips that can be removed", %{conn: conn} do
    product = product_fixture(tags: ["summer", "sale"])
    {:ok, lv, html} = live(conn, ~p"/products/#{product}/edit")
    assert html =~ "Remove tag summer"

    html = lv |> element("button[phx-value-tag=summer]") |> render_click()
    refute html =~ "Remove tag summer"
    assert html =~ "Remove tag sale"
    assert html =~ ~s(value="sale")
  end

  test "the stock input has stepper buttons", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/products/new")
    assert html =~ ~s(data-step-target="product_stock")
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

  describe "when someone else saves the product" do
    test "the form says so and can load their version", %{conn: conn} do
      product = product_fixture(%{title: "Old title"})
      {:ok, lv, _html} = live(conn, ~p"/products/#{product}/edit")
      refute has_element?(lv, "#newer-version")

      {:ok, _} = ClothingStore.Products.update_product(product, %{title: "Their title"})
      assert render(lv) =~ "Changed: Title."

      html = lv |> element("#newer-version button", "Load their version") |> render_click()
      refute html =~ "newer-version"
      assert html =~ ~s(value="Their title")
      assert html =~ ~s(name="product[lock_version]" value="#{product.lock_version + 1}")
    end

    test "keeping my changes saves them over theirs", %{conn: conn} do
      product = product_fixture(%{title: "Old title"})
      {:ok, lv, _html} = live(conn, ~p"/products/#{product}/edit")
      lv |> form("#product-form", product: %{title: "My title"}) |> render_change()

      # a sale also changes the product
      {:ok, _} = ClothingStore.Products.restock_product(product)
      assert render(lv) =~ "Changed: Stock."

      html = lv |> element("#newer-version button", "Keep my changes") |> render_click()
      assert html =~ ~s(value="My title")

      form = form(lv, "#product-form")
      render_submit(form)
      conn = follow_trigger_action(form, conn)
      assert redirected_to(conn) == ~p"/products/#{product}"
      assert ClothingStore.Products.get_product!(product.id).title == "My title"
    end

    test "other products' saves change nothing", %{conn: conn} do
      product = product_fixture()
      other = product_fixture()
      {:ok, lv, _html} = live(conn, ~p"/products/#{product}/edit")

      {:ok, _} = ClothingStore.Products.update_product(other, %{title: "Elsewhere"})
      refute render(lv) =~ "newer-version"
    end
  end

  describe "photo upload" do
    setup do
      Photos.clear()
      on_exit(&Photos.clear/0)
    end

    test "an uploaded photo fills the photo field and is saved", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/products/new")
      {:ok, image} = Operation.black(40, 30, bands: 3)
      {:ok, png} = Image.write_to_buffer(image, ".png")

      photo =
        file_input(lv, "#product-form", :photo, [
          %{name: "shirt.png", content: png, type: "image/png"}
        ])

      render_upload(photo, "shirt.png")
      html = render(lv)

      assert [_, path] =
               Regex.run(~r|id="photo-preview" src="(/uploads/[0-9a-f]{32}\.webp)"|, html)

      assert has_element?(lv, ~s|#product_photo[value="#{path}"]|)

      # follow_trigger_action posts only the values given here, so pass what the page now holds
      form = form(lv, "#product-form", product: %{@valid | photo: path})
      render_submit(form)
      conn = follow_trigger_action(form, conn)
      %{id: id} = redirected_params(conn)
      assert ClothingStore.Products.get_product!(id).photo == path
    end

    test "a file that is not an image is refused", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/products/new")

      photo =
        file_input(lv, "#product-form", :photo, [
          %{name: "evil.png", content: "<svg onload=alert(1)>", type: "image/png"}
        ])

      render_upload(photo, "evil.png")
      assert render(lv) =~ "Choose a JPEG, PNG or WebP image."
      refute render(lv) =~ "/uploads/"
    end
  end
end
