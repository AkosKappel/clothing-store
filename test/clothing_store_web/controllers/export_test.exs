defmodule ClothingStoreWeb.ExportTest do
  use ClothingStoreWeb.ConnCase, async: true

  import ClothingStore.ProductsFixtures
  import ClothingStore.TransactionsFixtures

  alias ClothingStoreWeb.CSV

  test "CSV.encode/1 quotes separators and defuses formulas" do
    assert CSV.encode([["a,b", ~s(say "hi"), "=1+1", 3, nil]]) ==
             ~s("a,b","say ""hi""",'=1+1,3,) <> "\r\n"
  end

  describe "logged in" do
    setup :register_and_log_in_user

    test "the inventory export follows the filters", %{conn: conn} do
      product_fixture(title: "Linen shirt", category: "Shirts")
      product_fixture(title: "Wool coat", category: "Coats")

      conn = get(conn, ~p"/inventory.csv?category=Shirts")
      assert response_content_type(conn, :csv)
      assert get_resp_header(conn, "content-disposition") |> hd() =~ "inventory-"

      body = response(conn, 200)
      assert body =~ "id,title,category,tags,price,stock,updated_at\r\n"
      assert body =~ "Linen shirt"
      refute body =~ "Wool coat"
    end

    test "the transactions export lists the month's line items", %{conn: conn} do
      shirt = product_fixture(title: "Linen shirt", price: "20.00")
      sale_fixture([{shirt, 2}], ~U[2026-09-10 10:00:00Z])
      sale_fixture([{shirt, 5}], ~U[2026-08-10 10:00:00Z])

      body = conn |> get(~p"/transactions.csv?month=2026-09") |> response(200)

      assert [_header, row] = String.split(body, "\r\n", trim: true)
      assert row =~ ~r/,2026-09-10T10:00:00Z,\d+,Linen shirt,2,20.00,40.00$/
    end
  end

  test "exports need a login", %{conn: conn} do
    assert conn |> get(~p"/inventory.csv") |> redirected_to() == ~p"/users/log_in"
    assert build_conn() |> get(~p"/transactions.csv") |> redirected_to() == ~p"/users/log_in"
  end
end
