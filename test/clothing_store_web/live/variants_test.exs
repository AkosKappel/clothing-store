defmodule ClothingStoreWeb.VariantsTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  alias ClothingStore.{Products, Transactions}

  setup :register_and_log_in_user

  defp with_sizes(stocks) do
    product_fixture(
      stock: 999,
      variants: for({size, stock} <- stocks, do: %{size: size, stock: stock})
    )
  end

  test "the stock of a product with sizes is their total" do
    product = with_sizes([{"S", 2}, {"M", 5}])
    assert product.stock == 7

    {:ok, product} =
      Products.update_product(product, %{
        "stock" => "100",
        "variants" => %{"0" => %{"id" => hd(product.variants).id, "size" => "S", "stock" => "4"}}
      })

    assert product.stock == 4
    assert [%{size: "S", stock: 4}] = product.variants
  end

  test "a size can't be listed twice" do
    assert {:error, changeset} =
             Products.create_product(%{
               title: "Shirt",
               description: "d",
               category: "c",
               photo: "/images/logo.svg",
               price: "10",
               stock: 0,
               variants: [%{size: "M", stock: 1}, %{size: "M", stock: 2}]
             })

    assert %{variants: [%{}, %{size: ["is listed twice"]}]} =
             ClothingStore.DataCase.errors_on(changeset)
  end

  test "sales and restocks keep the sizes adding up" do
    product = with_sizes([{"S", 3}, {"M", 0}, {"L", 3}])
    {:ok, _} = Transactions.record_sale([{product, 2}])
    {:ok, restocked} = Products.restock_product(product)

    product = Products.get_product!(product.id)
    assert product.stock == restocked.stock
    assert product.stock == 14
    assert product.stock == product.variants |> Enum.map(& &1.stock) |> Enum.sum()
    # the restock went to the size with the least stock
    assert Enum.find(product.variants, &(&1.size == "M")).stock == 10
  end

  test "the form adds and removes sizes, and the page lists them", %{conn: conn} do
    product = with_sizes([{"S", 2}])
    {:ok, lv, _html} = live(conn, ~p"/products/#{product}/edit")

    assert has_element?(lv, "button", "Add a size")

    # what the Add and Remove buttons send with the change event
    html =
      lv
      |> form("#product-form")
      |> render_change(%{"product" => %{"variants_sort" => ["0", "new"]}})

    assert html =~ ~s(name="product[variants][1][size]")
    assert html =~ "The total of the sizes below"

    html =
      lv |> form("#product-form") |> render_change(%{"product" => %{"variants_drop" => ["0"]}})

    refute html =~ ~s(name="product[variants][1][size]")

    html = conn |> get(~p"/products/#{product}") |> html_response(200)
    assert html =~ ~s(aria-label="Stock per size")
  end
end
