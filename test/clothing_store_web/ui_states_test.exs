defmodule ClothingStoreWeb.UIStatesTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  describe "logged out" do
    test "the header shows only About, not the dashboard links or a second Log in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      assert has_element?(lv, ~s|#menu a[href="/about"]|)
      refute has_element?(lv, ~s|#menu a[href="/products"]|)
      refute has_element?(lv, ~s|#menu a[href="/users/log_in"]|)
    end
  end

  describe "logged in" do
    setup :register_and_log_in_user

    test "the nav marks the current page, including LiveViews", %{conn: conn} do
      html = conn |> get(~p"/transactions") |> html_response(200)
      assert html =~ ~r|href="/transactions"[^>]*aria-current="page"|

      {:ok, lv, _html} = live(conn, ~p"/")
      assert has_element?(lv, ~s|#menu a[href="/"][aria-current="page"]|)
      refute has_element?(lv, ~s|#menu a[href="/products"][aria-current]|)
    end

    test "the dashboard and inventory explain an empty catalogue", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "No products yet"

      html = conn |> get(~p"/products") |> html_response(200)
      assert html =~ "No products yet"
      refute html =~ "Clear filters"
    end

    test "the inventory tells filtered-out results apart from an empty catalogue", %{conn: conn} do
      product_fixture(%{title: "Linen shirt", price: "20"})

      html = conn |> get(~p"/products?min_price=500") |> html_response(200)
      assert html =~ "No products match these filters"
      assert html =~ "Clear filters"
      refute html =~ "Linen shirt"

      html = conn |> get(~p"/products") |> html_response(200)
      assert html =~ "Linen shirt"
      assert html =~ "1 product"
    end

    test "deleting asks for confirmation in a dialog that sends a DELETE", %{conn: conn} do
      product = product_fixture()

      html = conn |> get(~p"/products/#{product}") |> html_response(200)
      assert html =~ ~s|commandfor="delete-product"|
      assert html =~ ~r|<dialog id="delete-product"|
      assert html =~ ~s|action="/products/#{product.id}"|
      assert html =~ ~r|<input name="_method"[^>]*value="delete"|
    end

    test "transactions explain an empty month", %{conn: conn} do
      html = conn |> get(~p"/transactions?month=2024-01") |> html_response(200)
      assert html =~ "No transactions in January 2024"
      assert html =~ "Show all"

      html = conn |> get(~p"/transactions") |> html_response(200)
      assert html =~ "No transactions yet"
    end

    test "statistics name the months and explain missing sales", %{conn: conn} do
      this_month = Date.utc_today() |> Date.beginning_of_month()
      last_month = this_month |> Date.add(-1)

      html = conn |> get(~p"/statistics") |> html_response(200)
      assert html =~ "This month (#{Calendar.strftime(this_month, "%B %Y")})"
      assert html =~ "Last month (#{Calendar.strftime(last_month, "%B %Y")})"
      assert html =~ "No sales recorded yet."
    end
  end
end
