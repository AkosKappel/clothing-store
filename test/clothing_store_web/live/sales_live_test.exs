defmodule ClothingStoreWeb.SalesLiveTest do
  # not async: the pages listen on the shared "products" topic
  use ClothingStoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures
  import ClothingStore.TransactionsFixtures

  setup :register_and_log_in_user

  describe "transactions" do
    test "the month filter and month buttons patch the URL", %{conn: conn} do
      shirt = product_fixture(title: "Linen shirt")
      sale_fixture([{shirt, 1}], ~U[2026-09-10 10:00:00Z])
      {:ok, lv, _html} = live(conn, ~p"/transactions")

      lv |> form("#month-filter", month: "2026-09") |> render_submit()
      assert_patch(lv, ~p"/transactions?month=2026-09")
      assert render(lv) =~ "Sales in September 2026."

      lv |> element("a", "Aug 2026") |> render_click()
      assert_patch(lv, ~p"/transactions?month=2026-08")
      assert render(lv) =~ "No transactions in August 2026"

      lv |> form("#month-filter", month: "nonsense") |> render_submit()
      assert_patch(lv, ~p"/transactions")
    end

    test "a renamed product shows up without a reload", %{conn: conn} do
      shirt = product_fixture(title: "Linen shirt")
      sale_fixture([{shirt, 1}])
      {:ok, lv, _html} = live(conn, ~p"/transactions")

      {:ok, _} = ClothingStore.Products.update_product(shirt, %{title: "Hemp shirt"})
      assert render(lv) =~ "Hemp shirt"
    end
  end

  describe "statistics" do
    test "stock alerts update when stock changes elsewhere", %{conn: conn} do
      product = product_fixture(stock: 50)
      {:ok, lv, html} = live(conn, ~p"/statistics")
      assert html =~ "0 products"

      {:ok, _} = ClothingStore.Products.update_product(product, %{stock: 0})
      assert render(lv) =~ "1 product"
    end
  end
end
