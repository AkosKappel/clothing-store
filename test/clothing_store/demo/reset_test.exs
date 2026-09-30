defmodule ClothingStore.Demo.ResetTest do
  # TRUNCATE is transactional in Postgres, so the sandbox rolls it back; async: false
  # because it locks every table the other tests use.
  use ClothingStore.DataCase, async: false

  alias ClothingStore.{Demo, Products, Repo, Users}
  import ClothingStore.ProductsFixtures

  test "wipes visitor changes, reseeds and notifies live views" do
    product_fixture(%{title: "Visitor product"})
    Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")

    assert :ok = Demo.Reset.run()

    titles = Enum.map(Products.list_products(), & &1.title)
    refute "Visitor product" in titles
    assert "T-Shirt" in titles
    assert length(titles) == 10
    assert Users.get_user_by_email(Demo.account().email)
    assert Repo.aggregate(ClothingStore.Transactions.Transaction, :count) > 0
    assert_receive :demo_reset
  end
end
