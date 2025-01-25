defmodule ClothingStore.ProductsTest do
  use ClothingStore.DataCase

  alias ClothingStore.Products

  describe "products" do
    alias ClothingStore.Products.Product

    import ClothingStore.ProductsFixtures

    @invalid_attrs %{description: nil, title: nil, category: nil, photo: nil, price: nil, stock: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{description: "some description", title: "some title", category: "some category", photo: "some photo", price: "120.5", stock: 42}

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.description == "some description"
      assert product.title == "some title"
      assert product.category == "some category"
      assert product.photo == "some photo"
      assert product.price == Decimal.new("120.5")
      assert product.stock == 42
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", category: "some updated category", photo: "some updated photo", price: "456.7", stock: 43}

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.description == "some updated description"
      assert product.title == "some updated title"
      assert product.category == "some updated category"
      assert product.photo == "some updated photo"
      assert product.price == Decimal.new("456.7")
      assert product.stock == 43
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, @invalid_attrs)
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Products.change_product(product)
    end
  end
end
