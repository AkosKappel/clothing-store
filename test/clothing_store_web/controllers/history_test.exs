defmodule ClothingStoreWeb.HistoryTest do
  use ClothingStoreWeb.ConnCase, async: true

  import ClothingStore.ProductsFixtures

  alias ClothingStore.Products

  setup :register_and_log_in_user

  test "a deleted product can be brought back from the toast's Undo", %{conn: conn} do
    product = product_fixture(title: "Linen shirt")

    conn = delete(conn, ~p"/products/#{product}")
    html = conn |> get(redirected_to(conn)) |> html_response(200)
    assert html =~ "Linen shirt was deleted."
    assert html =~ ~s(action="/products/#{product.id}/restore")
    refute html =~ ~s(href="/products/#{product.id}")

    conn = conn |> recycle() |> post(~p"/products/#{product}/restore")
    assert redirected_to(conn) == ~p"/products/#{product}"
    assert Products.get_product!(product.id).title == "Linen shirt"
  end

  test "deleted products are purged after the undo window" do
    product = product_fixture()
    {:ok, _} = Products.delete_product(product)

    assert Products.purge_deleted(10) == 0
    assert Products.purge_deleted(-1) == 1
    assert Products.restore_product(product.id) == {:error, :not_found}
  end

  test "the history lists each change and restores earlier details", %{conn: conn} do
    product = product_fixture(title: "Linen shirt", price: "40.00", stock: 5)
    {:ok, _} = Products.update_product(product, %{title: "Hemp shirt", price: "45.00"})
    {:ok, _} = Products.restock_product(product)

    [restocked, edited, created] = Products.list_versions(product.id)

    assert {restocked.action, edited.action, created.action} ==
             {"restocked", "updated", "created"}

    assert edited.changes["title"] == ["Linen shirt", "Hemp shirt"]

    html = conn |> get(~p"/products/#{product}") |> html_response(200)
    assert html =~ "title Linen shirt → Hemp shirt"
    assert html =~ "Restore these details"

    conn = post(conn, ~p"/products/#{product}/versions/#{created.id}/revert")
    assert redirected_to(conn) == ~p"/products/#{product}"

    reverted = Products.get_product!(product.id)

    assert {reverted.title, Decimal.to_string(reverted.price), reverted.stock} ==
             {"Linen shirt", "40.00", 15}
  end

  test "versions of another product can't be restored", %{conn: conn} do
    product = product_fixture()
    other = product_fixture()
    [version] = Products.list_versions(other.id)

    assert {:error, :not_found} = Products.revert_to_version(product, version.id)
    conn = post(conn, ~p"/products/#{product}/versions/#{version.id}/revert")
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "can't be restored"
  end
end
