defmodule ClothingStoreWeb.MalformedParamsTest do
  use ClothingStoreWeb.ConnCase, async: true

  import ClothingStore.ProductsFixtures

  setup :register_and_log_in_user

  describe "transactions month filter" do
    for month <- ["abc", "2024-13", "2024-1", "2024-01-01", "-01"] do
      test "ignores month=#{inspect(month)}", %{conn: conn} do
        assert conn |> get(~p"/transactions?#{[month: unquote(month)]}") |> html_response(200)
      end
    end

    test "ignores a list-shaped month", %{conn: conn} do
      assert conn |> get("/transactions?month[]=x") |> html_response(200)
    end

    test "ignores a map-shaped month", %{conn: conn} do
      assert conn |> get("/transactions?month[a]=x") |> html_response(200)
    end

    test "still filters by a valid month", %{conn: conn} do
      assert conn |> get(~p"/transactions?month=2024-02") |> html_response(200)
    end
  end

  describe "product filters" do
    setup do
      %{product: product_fixture(%{title: "Filtered hat", category: "Hats", tags: ["red"]})}
    end

    for query <- [
          "category=x",
          "in_stock=true",
          "min_price=abc",
          "max_price=",
          "min_price[]=1",
          "category[a]=b",
          "tags[a]=b",
          "tags[]=x&tags[]=",
          "in_stock[]=true"
        ] do
      test "tolerates ?#{query}", %{conn: conn} do
        assert conn |> get("/products?" <> unquote(query)) |> html_response(200)
      end
    end

    test "still applies valid filters", %{conn: conn} do
      html =
        conn
        |> get("/products?category=Hats&min_price=1&in_stock=true&tags=red")
        |> html_response(200)

      assert html =~ "Filtered hat"

      html = conn |> get("/products?category=Shoes") |> html_response(200)
      refute html =~ "Filtered hat"
    end
  end

  test "a product id beyond bigint is a 404", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, "/products/99999999999999999999") end
    assert_error_sent 404, fn -> get(conn, "/products/99999999999999999999/edit") end
  end

  test "a map-shaped product create param does not crash", %{conn: conn} do
    conn =
      post(conn, ~p"/products",
        product: %{
          title: "t",
          description: "d",
          category: "c",
          photo: "/images/x.webp",
          price: "1",
          stock: "1",
          tags: %{"a" => "b"}
        }
      )

    assert conn.status in [200, 302]
  end
end
