defmodule ClothingStoreWeb.ProductController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.Products
  alias ClothingStore.Products.Product

  def index(conn, params) do
    # Convert tags parameter from string to list if present
    params = case params["tags"] do
      nil -> params
      tags -> Map.put(params, "tags", parse_tags(tags))
    end

    products = Products.list_products(params)
    categories = Products.list_categories()
    tags = Products.list_tags()

    render(conn, :index, products: products, filters: params, categories: categories, tags: tags)
  end

  defp parse_tags(tags) do
    case tags do
      nil -> []
      tags when is_list(tags) -> tags |> Enum.map(&String.trim/1) |> Enum.filter(&(&1 != ""))
      tags when is_binary(tags) -> tags |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.filter(&(&1 != ""))
    end
  end

  def new(conn, _params) do
    changeset = Products.change_product(%Product{})
    render(conn, :new, changeset: changeset)
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
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    render(conn, :show, product: product)
  end

  def edit(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)
    render(conn, :edit, product: product, changeset: changeset)
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
        render(conn, :edit, product: product, changeset: changeset)
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
