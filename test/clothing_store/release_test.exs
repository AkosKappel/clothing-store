defmodule ClothingStore.ReleaseTest do
  use ClothingStore.DataCase, async: true

  import ClothingStore.UsersFixtures
  import ClothingStore.ProductsFixtures

  alias ClothingStore.{Release, Repo}

  describe "fresh_database?/1" do
    test "true for an empty database" do
      assert Release.fresh_database?(Repo)
    end

    test "false when a user exists but no products" do
      user_fixture()
      refute Release.fresh_database?(Repo)
    end

    test "false when products exist" do
      product_fixture()
      refute Release.fresh_database?(Repo)
    end
  end
end
