defmodule ClothingStoreWeb.ProductController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.Products
  alias ClothingStore.Products.Product

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
    |> Map.take(~w(category min_price max_price in_stock))
    |> Map.filter(fn {_key, value} -> is_binary(value) end)
    |> Map.put("tags", parse_tags(params["tags"]))
  end

  defp parse_tags(tags) when is_binary(tags), do: tags |> String.split(",") |> clean_tags()
  defp parse_tags(tags) when is_list(tags), do: clean_tags(tags)
  # missing, or a map from ?tags[a]=b
  defp parse_tags(_tags), do: []

  defp clean_tags(tags) do
    tags |> Enum.filter(&is_binary/1) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  def new(conn, _params) do
    changeset = Products.change_product(%Product{})
    render(conn, :new, page_title: "New product", changeset: changeset)
  end

  def create(conn, %{"product" => product_params}) do
    tags = parse_tags(product_params["tags"])
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

  def edit(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)
    render(conn, :edit, page_title: "Edit product", product: product, changeset: changeset)
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Products.get_product!(id)

    tags = parse_tags(product_params["tags"])
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
