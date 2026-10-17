defmodule ClothingStore.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias ClothingStore.Products.Product
  alias ClothingStore.Repo

  # the public demo resets nightly; this keeps visitors from filling the database until then
  @max_products 200
  # pg_advisory_xact_lock key that serializes creates, so the cap can't be overshot
  @create_lock 7_201_001

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

  @doc "One page of the catalogue, newest first: `limit` products after the first `offset`."
  def page_products(offset, limit) do
    Product
    |> sort("newest")
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "How many products the catalogue holds."
  def count_products, do: Repo.aggregate(Product, :count)

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
    |> filter_low_stock(filters["low_stock"])
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

  defp filter_low_stock(query, "true"), do: from(p in query, where: p.stock <= ^@low_stock)
  defp filter_low_stock(query, _low_stock), do: query

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
  def catalogue_full?, do: count_products() >= @max_products

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
    changeset = Product.changeset(%Product{}, attrs)

    Repo.transaction(fn ->
      Repo.query!("SELECT pg_advisory_xact_lock($1)", [@create_lock])

      case changeset |> check_catalogue_limit() |> Repo.insert() do
        {:ok, product} -> product
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
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

  @max_import_rows 100
  # what a new product gets when the import leaves these columns out
  @import_defaults %{"description" => "Imported product.", "photo" => "/images/logo.svg"}
  @import_fields ~w(title category price stock tags description photo)

  @doc "The most rows one import may have."
  def max_import_rows, do: @max_import_rows

  @doc """
  Creates and updates products from imported rows: maps with string keys
  (`"id"`, `"title"`, `"category"`, `"price"`, `"stock"`, `"tags"`, `"description"`,
  `"photo"`). A row whose id matches a product updates the columns it has; any other
  row creates a product. Every row is validated first, and nothing is saved unless all
  of them are valid and the new products fit in the catalogue.

  Returns `{:ok, %{created: n, updated: n}}` or `{:error, [{row_number, message}]}`,
  where row 1 is the header line.
  """
  def import_products(rows) when length(rows) > @max_import_rows,
    do: {:error, [{1, "An import can have at most #{@max_import_rows} rows"}]}

  def import_products(rows) do
    plans = rows |> Enum.with_index(2) |> Enum.map(fn {row, line} -> {line, plan_import(row)} end)
    errors = for {line, {:error, message}} <- plans, do: {line, message}
    creates = Enum.count(plans, &match?({_, {:create, _}}, &1))

    cond do
      errors != [] ->
        {:error, errors}

      Repo.aggregate(Product, :count) + creates > @max_products ->
        {:error, [{1, "The import would go over the demo's limit of #{@max_products} products"}]}

      true ->
        {:ok, Enum.reduce(plans, %{created: 0, updated: 0}, &apply_import/2)}
    end
  end

  defp plan_import(row) do
    attrs =
      row
      |> Map.take(@import_fields)
      |> Map.reject(fn {_key, value} -> String.trim(value) == "" end)
      |> Map.update("tags", nil, &parse_tags/1)
      |> Map.reject(fn {_key, value} -> is_nil(value) end)

    {action, changeset} =
      case import_target(row["id"]) do
        nil -> {:create, Product.changeset(%Product{}, Map.merge(@import_defaults, attrs))}
        product -> {{:update, product}, Product.changeset(product, attrs)}
      end

    cond do
      not changeset.valid? -> {:error, changeset_message(changeset)}
      action == :create -> {:create, Map.merge(@import_defaults, attrs)}
      true -> {action, attrs}
    end
  end

  defp import_target(id) do
    case Ecto.Type.cast(:id, id) do
      {:ok, id} when id in 1..@max_id -> Repo.get(Product, id)
      _ -> nil
    end
  end

  defp apply_import({_line, {:create, attrs}}, counts) do
    {:ok, _} = create_product(attrs)
    Map.update!(counts, :created, &(&1 + 1))
  end

  defp apply_import({_line, {{:update, product}, attrs}}, counts) do
    {:ok, _} = update_product(product, attrs)
    Map.update!(counts, :updated, &(&1 + 1))
  end

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join("; ", fn {field, messages} -> "#{field} #{Enum.join(messages, ", ")}" end)
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

  @restock_amount 10

  @doc "How many items one restock adds."
  def restock_amount, do: @restock_amount

  @doc """
  Adds #{@restock_amount} to a product's stock, capped at the largest stock a product may have.
  The increment runs in the database, so two restocks at once both count.
  """
  def restock_product(%Product{id: id}) do
    max = Product.max_amount()

    from(p in Product,
      where: p.id == ^id,
      select: p,
      update: [set: [stock: fragment("LEAST(? + ?, ?)", p.stock, ^@restock_amount, ^max)]]
    )
    |> Repo.update_all(set: [updated_at: DateTime.utc_now(:second)])
    |> case do
      {1, [product]} -> notify_subscribers({:ok, product}, :product_updated)
      {0, []} -> {:error, :not_found}
    end
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
