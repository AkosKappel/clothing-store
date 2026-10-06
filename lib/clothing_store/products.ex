defmodule ClothingStore.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias ClothingStore.Products.Product
  alias ClothingStore.Repo

  # the public demo resets nightly; this keeps visitors from filling the database until then
  @max_products 200

  @max_id 9_223_372_036_854_775_807

  # a product with this many or fewer left counts as low on stock
  @low_stock 5

  @doc "The stock level at or below which a product is low on stock."
  def low_stock, do: @low_stock

  @doc "How many products are out of stock and how many are low (but not out)."
  def stock_alerts do
    from(p in Product,
      select: %{
        out: filter(count(p.id), p.stock == 0),
        low: filter(count(p.id), p.stock > 0 and p.stock <= ^@low_stock)
      }
    )
    |> Repo.one()
  end

  @doc "The most products the catalogue may hold."
  def max_products, do: @max_products

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products(filters \\ %{}) do
    Product
    |> apply_filters(filters)
    |> sort(filters["sort"])
    |> Repo.all()
  end

  @sorts [
    {"newest", "Newest first"},
    {"price_asc", "Price: low to high"},
    {"price_desc", "Price: high to low"},
    {"stock_asc", "Stock: low to high"},
    {"stock_desc", "Stock: high to low"},
    {"title", "Name: A to Z"}
  ]

  @doc "The inventory sort options as `{value, label}`; the first is the default."
  def sorts, do: @sorts

  # the id keeps the order stable when the sorted values tie
  defp sort(query, "price_asc"), do: order_by(query, [p], asc: p.price, desc: p.id)
  defp sort(query, "price_desc"), do: order_by(query, [p], desc: p.price, desc: p.id)
  defp sort(query, "stock_asc"), do: order_by(query, [p], asc: p.stock, desc: p.id)
  defp sort(query, "stock_desc"), do: order_by(query, [p], desc: p.stock, desc: p.id)

  defp sort(query, "title"),
    do: order_by(query, [p], asc: fragment("lower(?)", p.title), asc: p.id)

  defp sort(query, _newest), do: order_by(query, [p], desc: p.inserted_at, desc: p.id)

  # Filters come straight from query params: a missing, non-string or unparsable
  # value leaves that filter out rather than failing the request.
  defp apply_filters(query, filters) do
    query
    |> filter_category(filters["category"])
    |> filter_price(:min, parse_price(filters["min_price"]))
    |> filter_price(:max, parse_price(filters["max_price"]))
    |> filter_in_stock(filters["in_stock"])
    |> filter_tags(filters["tags"])
    |> filter_search(filters["q"])
  end

  # case-insensitive substring match on title, description, category and tags;
  # % and _ in the search are matched literally
  defp filter_search(query, search) when is_binary(search) do
    case String.trim(search) do
      "" ->
        query

      search ->
        pattern = "%" <> String.replace(search, ~r/[\\%_]/, "\\\\\\0") <> "%"

        from(p in query,
          where:
            ilike(p.title, ^pattern) or ilike(p.description, ^pattern) or
              ilike(p.category, ^pattern) or
              fragment("array_to_string(?, ' ') ILIKE ?", p.tags, ^pattern)
        )
    end
  end

  defp filter_search(query, _search), do: query

  defp filter_category(query, category) when is_binary(category) and category not in ["", "All"],
    do: from(p in query, where: p.category == ^category)

  defp filter_category(query, _category), do: query

  defp parse_price(price) when is_binary(price) do
    case Float.parse(price) do
      {value, _rest} -> value
      :error -> nil
    end
  end

  defp parse_price(_price), do: nil

  defp filter_price(query, _bound, nil), do: query
  defp filter_price(query, :min, value), do: from(p in query, where: p.price >= ^value)
  defp filter_price(query, :max, value), do: from(p in query, where: p.price <= ^value)

  defp filter_in_stock(query, "true"), do: from(p in query, where: p.stock > 0)
  defp filter_in_stock(query, _in_stock), do: query

  defp filter_tags(query, tags) when is_list(tags) and tags != [] do
    if Enum.all?(tags, &is_binary/1),
      do: from(p in query, where: fragment("? && ?", p.tags, ^tags)),
      else: query
  end

  defp filter_tags(query, _tags), do: query

  @doc """
  Turns tags from a form or query string ("a, b" or a list) into a clean list of strings.

      iex> parse_tags(" summer, ,sale ")
      ["summer", "sale"]
  """
  def parse_tags(tags) when is_binary(tags), do: tags |> String.split(",") |> clean_tags()
  def parse_tags(tags) when is_list(tags), do: clean_tags(tags)
  # missing, or a map from ?tags[a]=b
  def parse_tags(_tags), do: []

  defp clean_tags(tags) do
    tags |> Enum.filter(&is_binary/1) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  @doc "Whether the catalogue holds as many products as the demo allows."
  def catalogue_full?, do: Repo.aggregate(Product, :count) >= @max_products

  @doc """
  Returns the list of unique categories.

  ## Examples

      iex> list_categories()
      ["Clothing", "Electronics", ...]

  """
  def list_categories do
    [
      "All"
      | Product
        |> select([p], p.category)
        |> distinct(true)
        |> Repo.all()
    ]
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
  def get_product!(id) do
    # ids from the URL beyond bigint would crash the query; no product has one
    case Ecto.Type.cast(:id, id) do
      {:ok, id} when id in 1..@max_id -> Repo.get!(Product, id)
      _ -> raise Ecto.NoResultsError, queryable: Product
    end
  end

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
    |> check_catalogue_limit()
    |> Repo.insert()
    |> notify_subscribers(:product_created)
  end

  defp check_catalogue_limit(changeset) do
    if catalogue_full?() do
      Ecto.Changeset.add_error(
        changeset,
        :base,
        "The demo is limited to #{@max_products} products"
      )
    else
      changeset
    end
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
    |> notify_subscribers(:product_updated)
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
    |> notify_subscribers(:product_deleted)
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

  defp notify_subscribers({:ok, product}, event) do
    Phoenix.PubSub.broadcast(ClothingStore.PubSub, "products", {event, product})
    {:ok, product}
  end

  defp notify_subscribers(error, _event), do: error
end
