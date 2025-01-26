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
    query = apply_filters(Product, filters)
    Repo.all(query)
  end

  defp apply_filters(query, filters) when map_size(filters) > 0 do
    query =
      if filters["category"] != "All" and filters["category"] != "",
        do: from(p in query, where: p.category == ^filters["category"]),
        else: query

    query =
      case Float.parse(filters["min_price"]) do
        {value, _} -> from(p in query, where: p.price >= ^value)
        _ -> query
      end

    query =
      case Float.parse(filters["max_price"]) do
        {value, _} -> from(p in query, where: p.price <= ^value)
        _ -> query
      end

    query =
      if filters["in_stock"] == "true",
        do: from(p in query, where: p.stock > 0),
        else: query

    query =
      if tags = filters["tags"],
        do: from(p in query, where: fragment("? && ?", p.tags, ^tags)),
        else: query

    query
  end

  defp apply_filters(query, _filters), do: query

  @doc """
  Returns the list of unique categories.

  ## Examples

      iex> list_categories()
      ["Clothing", "Electronics", ...]

  """
  def list_categories do
    ["All" | Product
    |> select([p], p.category)
    |> distinct(true)
    |> Repo.all()]
  end

  @doc """
  Returns the list of unique tags across all products.

  ## Examples

      iex> list_tags()
      ["Summer", "Winter", "Sale", ...]

  """
  def list_tags do
    Product
    |> select([p], fragment("DISTINCT unnest(tags)"))
    |> Repo.all()
    |> Enum.sort()
  end

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
