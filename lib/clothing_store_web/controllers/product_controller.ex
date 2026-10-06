defmodule ClothingStoreWeb.ProductController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.Products

  def index(conn, params) do
    filters = filter_params(params)
    products = Products.list_products(filters)
    categories = Products.list_categories()
    tags = Products.list_tags()

    render(conn, :index,
      page_title: "Inventory",
      products: products,
      filters: filters,
      categories: categories,
      tags: tags
    )
  end

  # only string filters (and a list of tag strings) reach the query and the form
  defp filter_params(params) do
    params
    |> Map.take(~w(q category min_price max_price in_stock sort))
    |> Map.filter(fn {_key, value} -> is_binary(value) end)
    |> Map.update("q", nil, &String.slice(&1, 0, 100))
    |> Map.put("tags", Products.parse_tags(params["tags"]))
  end

  def create(conn, %{"product" => product_params}) do
    tags = Products.parse_tags(product_params["tags"])
    product_params = Map.put(product_params, "tags", tags)

    case Products.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product created successfully.")
        |> redirect(to: ~p"/products/#{product}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, page_title: "New product", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    render(conn, :show, page_title: product.title, product: product)
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Products.get_product!(id)

    tags = Products.parse_tags(product_params["tags"])
    product_params = Map.put(product_params, "tags", tags)

    case Products.update_product(product, product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product updated successfully.")
        |> redirect(to: ~p"/products/#{product}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, page_title: "Edit product", product: product, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    {:ok, _product} = Products.delete_product(product)

    conn
    |> put_flash(:info, "Product deleted successfully.")
    |> redirect(to: ~p"/products")
  end
end
