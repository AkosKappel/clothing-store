defmodule ClothingStoreWeb.ProductControllerTest do
  use ClothingStoreWeb.ConnCase

  import ClothingStore.ProductsFixtures

  setup :register_and_log_in_user

  @create_attrs %{
    description: "some description",
    title: "some title",
    category: "some category",
    photo: "/images/products/white-t-shirt.webp",
    price: "120.5",
    stock: 42
  }
  @update_attrs %{
    description: "some updated description",
    title: "some updated title",
    category: "some updated category",
    photo: "https://images.pexels.com/photos/1/shirt.jpeg",
    price: "456.7",
    stock: 43
  }
  @invalid_attrs %{
    description: nil,
    title: nil,
    category: nil,
    photo: nil,
    price: nil,
    stock: nil
  }

  describe "index" do
    test "lists all products", %{conn: conn} do
      conn = get(conn, ~p"/products")
      assert html_response(conn, 200) =~ "Inventory"
    end
  end

  describe "new product" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/products/new")
      assert html_response(conn, 200) =~ "New Product"
      assert html_response(conn, 200) =~ "images.pexels.com or images.unsplash.com"
    end
  end

  describe "create product" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/products", product: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/products/#{id}"

      conn = get(conn, ~p"/products/#{id}")
      response = html_response(conn, 200)
      assert response =~ "Product Details"
      assert response =~ "some title"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/products", product: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Product"
    end

    test "rejects an over-long title", %{conn: conn} do
      conn =
        post(conn, ~p"/products", product: %{@create_attrs | title: String.duplicate("a", 101)})

      assert html_response(conn, 200) =~ "should be at most 100 character(s)"
    end

    test "shows the catalogue limit", %{conn: conn} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      rows =
        for i <- 1..ClothingStore.Products.max_products() do
          Map.merge(@create_attrs, %{
            title: "p#{i}",
            price: Decimal.new(1),
            inserted_at: now,
            updated_at: now
          })
        end

      ClothingStore.Repo.insert_all(ClothingStore.Products.Product, rows)

      conn = post(conn, ~p"/products", product: @create_attrs)
      assert html_response(conn, 200) =~ "The demo is limited to 200 products"
    end
  end

  describe "edit product" do
    setup [:create_product]

    test "renders form for editing chosen product", %{conn: conn, product: product} do
      conn = get(conn, ~p"/products/#{product}/edit")
      assert html_response(conn, 200) =~ "Edit Product"
    end
  end

  describe "update product" do
    setup [:create_product]

    test "redirects when data is valid", %{conn: conn, product: product} do
      conn = put(conn, ~p"/products/#{product}", product: @update_attrs)
      assert redirected_to(conn) == ~p"/products/#{product}"

      conn = get(conn, ~p"/products/#{product}")
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, product: product} do
      conn = put(conn, ~p"/products/#{product}", product: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Product"
    end
  end

  describe "delete product" do
    setup [:create_product]

    test "deletes chosen product", %{conn: conn, product: product} do
      conn = delete(conn, ~p"/products/#{product}")
      assert redirected_to(conn) == ~p"/products"

      {404, _headers, body} =
        assert_error_sent 404, fn ->
          get(conn, ~p"/products/#{product}")
        end

      assert body =~ "Page not found"
    end
  end

  describe "show product forecast" do
    import ClothingStore.TransactionsFixtures

    test "suggests a reorder and draws the daily sales", %{conn: conn} do
      product = product_fixture(stock: 1)
      sale_fixture([{product, 5}])

      html = conn |> get(~p"/products/#{product}") |> html_response(200)
      assert html =~ "Suggested reorder: 4"
      assert html =~ ~s(id="sales-sparkline")
      assert html =~ "5 in total"
    end
  end

  describe "restock product" do
    test "adds stock and shows the button only while stock is low", %{conn: conn} do
      product = product_fixture(stock: 2)
      assert conn |> get(~p"/products/#{product}") |> html_response(200) =~ "Restock +10"

      conn = post(conn, ~p"/products/#{product}/restock")
      assert redirected_to(conn) == ~p"/products/#{product}"

      html = conn |> get(~p"/products/#{product}") |> html_response(200)
      assert html =~ "now has 12 in stock"
      refute html =~ "Restock +10"
    end

    test "the low stock filter lists low and sold-out products", %{conn: conn} do
      product_fixture(title: "Plenty", stock: 50)
      product_fixture(title: "Almost gone", stock: 1)

      html = conn |> get(~p"/products?low_stock=true") |> html_response(200)
      assert html =~ "Almost gone"
      refute html =~ "Plenty"
    end
  end

  defp create_product(_) do
    product = product_fixture()
    %{product: product}
  end
end
