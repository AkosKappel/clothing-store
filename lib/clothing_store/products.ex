defmodule ClothingStore.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias ClothingStore.Repo

  alias ClothingStore.Products.Product

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products(filters \\ %{}) do
    Product
    |> apply_filters(filters)
    |> Repo.all()
  end

  defp apply_filters(query, %{"category" => category}) when category != "" do
    from(p in query, where: p.category == ^category)
  end

  defp apply_filters(query, %{"min_price" => min_price}) when min_price != "" do
    from(p in query, where: p.price >= ^String.to_float(min_price))
  end

  defp apply_filters(query, %{"max_price" => max_price}) when max_price != "" do
    from(p in query, where: p.price <= ^String.to_float(max_price))
  end

  defp apply_filters(query, %{"in_stock" => "true"}) do
    from(p in query, where: p.stock > 0)
  end

  defp apply_filters(query, _), do: query

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
