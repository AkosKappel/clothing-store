defmodule ClothingStore.ProductsTest do
  use ClothingStore.DataCase

  alias ClothingStore.Products

  describe "products" do
    alias ClothingStore.Products.Product

    import ClothingStore.ProductsFixtures

    @invalid_attrs %{
      description: nil,
      title: nil,
      category: nil,
      photo: nil,
      price: nil,
      stock: nil
    }

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Products.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Products.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{
        description: "some description",
        title: "some title",
        category: "some category",
        photo: "/images/products/white-t-shirt.webp",
        price: "120.5",
        stock: 42
      }

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.description == "some description"
      assert product.title == "some title"
      assert product.category == "some category"
      assert product.photo == "/images/products/white-t-shirt.webp"
      assert product.price == Decimal.new("120.5")
      assert product.stock == 42
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        category: "some updated category",
        photo: "https://images.pexels.com/photos/1/shirt.jpeg",
        price: "456.7",
        stock: 43
      }

      assert {:ok, %Product{} = product} = Products.update_product(product, update_attrs)
      assert product.description == "some updated description"
      assert product.title == "some updated title"
      assert product.category == "some updated category"
      assert product.photo == "https://images.pexels.com/photos/1/shirt.jpeg"
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

  describe "product validations" do
    alias ClothingStore.Products.Product

    import ClothingStore.ProductsFixtures

    @valid %{
      description: "d",
      title: "t",
      category: "c",
      photo: "/images/products/white-t-shirt.webp",
      price: "10",
      stock: 1,
      tags: ["a"]
    }

    defp errors_on_attrs(attrs),
      do: errors_on(Product.changeset(%Product{}, Map.merge(@valid, attrs)))

    test "limits text field lengths" do
      assert "should be at most 100 character(s)" in errors_on_attrs(%{
               title: String.duplicate("a", 101)
             }).title

      assert "should be at most 50 character(s)" in errors_on_attrs(%{
               category: String.duplicate("a", 51)
             }).category

      assert "should be at most 2000 character(s)" in errors_on_attrs(%{
               description: String.duplicate("a", 2001)
             }).description

      assert "should be at most 500 byte(s)" in errors_on_attrs(%{
               photo: "/images/" <> String.duplicate("a", 500)
             }).photo

      assert errors_on_attrs(%{title: String.duplicate("a", 100)}) == %{}
    end

    test "accepts only local /images/ paths and allowlisted https image hosts" do
      for ok <- [
            "/images/products/white-t-shirt.webp",
            "https://images.pexels.com/photos/1/a.jpeg?w=600",
            "https://images.unsplash.com/photo-1?auto=format"
          ] do
        assert errors_on_attrs(%{photo: ok}) == %{}, ok
      end

      for bad <- [
            "some photo",
            "/images/../secret",
            "/images/a/../../x",
            "/uploads/x.png",
            "//evil.example/x.png",
            "http://images.pexels.com/x.jpeg",
            "https://evil.example/x.png",
            "https://images.pexels.com.evil.example/x.png",
            "https://user@evil.example/x.png",
            "javascript:alert(1)",
            "data:image/png;base64,AAAA"
          ] do
        assert %{photo: [msg]} = errors_on_attrs(%{photo: bad}), bad
        assert msg =~ "/images/"
        assert msg =~ "images.pexels.com"
      end
    end

    test "caps text fields by bytes, not just graphemes" do
      # one grapheme, but 1 + 2 * 50_000 bytes of combining acute accents
      zalgo = "a" <> String.duplicate("\u0301", 50_000)
      assert String.length(zalgo) == 1

      assert %{title: [_]} = errors_on_attrs(%{title: zalgo})
      assert %{category: [_]} = errors_on_attrs(%{category: zalgo})
      assert %{description: [_]} = errors_on_attrs(%{description: zalgo})
      assert %{photo: [_]} = errors_on_attrs(%{photo: "/images/" <> zalgo})
      assert %{tags: [_]} = errors_on_attrs(%{tags: [zalgo]})

      # ordinary multi-byte text within the limits still passes
      assert errors_on_attrs(%{
               title: String.duplicate("é", 100),
               tags: [String.duplicate("é", 30)]
             }) ==
               %{}
    end

    test "limits tag count and tag length" do
      assert %{tags: [_]} = errors_on_attrs(%{tags: Enum.map(1..11, &"t#{&1}")})
      assert %{tags: [_]} = errors_on_attrs(%{tags: [String.duplicate("a", 31)]})
      # Ecto drops blank array elements when casting, so a tag is never empty
      assert Product.changeset(%Product{}, %{tags: ["a", "", " "]}).changes.tags == ["a"]
      assert errors_on_attrs(%{tags: Enum.map(1..10, &"t#{&1}")}) == %{}
    end

    test "bounds price and stock" do
      assert %{price: [_]} = errors_on_attrs(%{price: "-1"})
      assert %{price: [_]} = errors_on_attrs(%{price: "100000.01"})
      assert %{stock: [_]} = errors_on_attrs(%{stock: -1})
      assert %{stock: [_]} = errors_on_attrs(%{stock: 100_001})
      assert errors_on_attrs(%{price: "100000", stock: 100_000}) == %{}
      assert errors_on_attrs(%{price: "0", stock: 0}) == %{}
    end

    defp fill_catalogue(count) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      rows =
        for i <- 1..count do
          Map.merge(@valid, %{
            title: "p#{i}",
            price: Decimal.new(1),
            inserted_at: now,
            updated_at: now
          })
        end

      Repo.insert_all(Product, rows)
    end

    test "create_product/1 refuses once the catalogue limit is reached" do
      limit = Products.max_products()
      fill_catalogue(limit - 1)
      assert {:ok, _} = Products.create_product(@valid)

      assert {:error, changeset} = Products.create_product(@valid)
      assert "The demo is limited to #{limit} products" in errors_on(changeset).base
      assert Repo.aggregate(Product, :count) == limit
    end

    test "update_product/2 still works at the catalogue limit" do
      product = product_fixture()
      fill_catalogue(Products.max_products() - 1)
      assert {:ok, _} = Products.update_product(product, %{title: "renamed"})
    end
  end

  describe "list_products/1 search and sort" do
    import ClothingStore.ProductsFixtures

    setup do
      %{
        linen:
          product_fixture(%{title: "Linen shirt", price: "50.00", stock: 3, tags: ["summer"]}),
        boots:
          product_fixture(%{title: "Chelsea boots", price: "150.00", stock: 0, tags: ["winter"]}),
        sale: product_fixture(%{title: "100% wool scarf", price: "20.00", stock: 9, tags: []})
      }
    end

    defp titles(filters), do: Products.list_products(filters) |> Enum.map(& &1.title)

    test "searches title, description, category and tags case-insensitively" do
      assert titles(%{"q" => "LINEN"}) == ["Linen shirt"]
      assert titles(%{"q" => "winter"}) == ["Chelsea boots"]
      assert titles(%{"q" => "  "}) |> length() == 3
    end

    test "matches % and _ literally" do
      assert titles(%{"q" => "100%"}) == ["100% wool scarf"]
      assert titles(%{"q" => "%"}) == ["100% wool scarf"]
      assert titles(%{"q" => "_"}) == []
    end

    test "sorts by price, stock and name; unknown sorts fall back to newest" do
      assert titles(%{"sort" => "price_asc"}) == [
               "100% wool scarf",
               "Linen shirt",
               "Chelsea boots"
             ]

      assert titles(%{"sort" => "stock_desc"}) == [
               "100% wool scarf",
               "Linen shirt",
               "Chelsea boots"
             ]

      assert titles(%{"sort" => "title"}) == ["100% wool scarf", "Chelsea boots", "Linen shirt"]
      assert titles(%{"sort" => "drop table"}) == titles(%{})
    end
  end
end
