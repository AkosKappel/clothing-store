defmodule ClothingStoreWeb.ProductImportLiveTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  alias ClothingStore.Products
  alias ClothingStoreWeb.CSV
  alias ClothingStoreWeb.ProductLive.Import

  setup :register_and_log_in_user

  test "CSV.decode/1 reads what CSV.encode/1 writes" do
    rows = [
      ["id", "title"],
      ["1", "a,b"],
      ["2", ~s(say "hi")],
      ["3", "line\nbreak"],
      ["4", "Žltý"]
    ]

    assert CSV.decode(CSV.encode(rows)) == {:ok, rows}
    assert CSV.decode(<<0xEF, 0xBB, 0xBF>> <> "a,b\n\nc,\n") == {:ok, [["a", "b"], ["c", ""]]}
    assert CSV.decode(~s("open)) == :error
  end

  test "an export can be edited and imported back" do
    product = product_fixture(title: "Linen shirt", stock: 3)

    csv =
      CSV.encode([
        ~w(id title category tags price stock),
        [product.id, "Linen shirt", "Shirts", "summer, linen", "39.90", 12],
        [nil, "=Wool coat", "Coats", "", "199", 4]
      ])

    assert Import.import_csv(csv) == {:ok, %{created: 1, updated: 1}}
    assert %{stock: 12, tags: ["summer", "linen"]} = Products.get_product!(product.id)

    assert [%{title: "=Wool coat", photo: "/images/logo.svg"}] =
             Products.list_products(%{"q" => "Wool"})
  end

  test "one invalid row imports nothing and names the line" do
    csv = "title,category,price,stock\nGood,Shirts,10,1\nBad,Shirts,-5,1\n"

    assert {:error, [{3, message}]} = Import.import_csv(csv)
    assert message =~ "price must be greater than or equal to 0"
    assert Products.list_products(%{"q" => "Good"}) == []
  end

  test "files without usable columns are refused" do
    assert {:error, [{1, _}]} = Import.import_csv("foo,bar\n1,2\n")
    assert {:error, [{1, _}]} = Import.import_csv(~s("broken))
  end

  test "the page imports an uploaded file", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/products/import")

    file =
      file_input(lv, "#import-form", :csv, [
        %{name: "products.csv", content: "title,category,price,stock\nCanvas tote,Bags,24.90,5\n"}
      ])

    render_upload(file, "products.csv")
    html = lv |> form("#import-form") |> render_submit()

    assert html =~ "1 added, 0 updated"
    assert [_] = Products.list_products(%{"q" => "Canvas tote"})
  end
end
