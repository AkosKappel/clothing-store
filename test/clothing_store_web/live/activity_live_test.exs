defmodule ClothingStoreWeb.ActivityLiveTest do
  # not async: the feed listens on the shared "activity" topic
  use ClothingStoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  alias ClothingStore.{ActivityFeed, Products, Transactions}

  setup :register_and_log_in_user

  test "product changes and sales are recorded with their details" do
    product = product_fixture(title: "Jeans", stock: 5, price: "79.90")
    {:ok, _} = Products.update_product(product, %{stock: 3, price: "69.90", description: "new"})
    {:ok, _} = Transactions.record_sale([{Products.get_product!(product.id), 2}])
    {:ok, _} = Products.delete_product(Products.get_product!(product.id))

    assert [deleted, sale, updated, created] =
             ActivityFeed.recent() |> Enum.filter(&(&1.product_title in ["Jeans", nil]))

    assert created.kind == "created"
    assert %{"stock" => [5, 3], "price" => ["79.90", "69.90"]} = updated.data["changes"]
    assert sale.data["items"] == [["Jeans", 2]]
    assert deleted.kind == "deleted"
  end

  test "an update that changes nothing tracked isn't recorded" do
    product = product_fixture()
    count = length(ActivityFeed.recent())
    {:ok, _} = Products.update_product(product, %{title: product.title})
    assert length(ActivityFeed.recent()) == count
  end

  test "the feed page and the dashboard show new events live", %{conn: conn} do
    product = product_fixture(title: "Jeans", stock: 5)
    {:ok, feed, _html} = live(conn, ~p"/activity")
    {:ok, dashboard, _html} = live(conn, ~p"/")

    {:ok, _} = Products.update_product(product, %{stock: 3})

    assert render(feed) =~ "stock 5 → 3"
    assert render(dashboard) =~ "stock 5 → 3"
  end
end
