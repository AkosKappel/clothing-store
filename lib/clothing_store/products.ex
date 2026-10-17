defmodule ClothingStore.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias ClothingStore.ActivityFeed
  alias ClothingStore.Products.{Product, Variant, Version}
  alias ClothingStore.Repo

  # the public demo resets nightly; this keeps visitors from filling the database until then
  @max_products 200
  @snapshot_fields ~w(title description category price stock tags photo discount_percent discount_starts_on discount_ends_on)a
  # what restoring a version puts back: everything but the stock
  @revertable Enum.map(@snapshot_fields -- [:stock], &to_string/1)
  # pg_advisory_xact_lock key that serializes creates, so the cap can't be overshot
  @create_lock 7_201_001

  @max_id 9_223_372_036_854_775_807

  # a product with this many or fewer left counts as low on stock
  @low_stock 5

  @doc "Products that aren't deleted, the base of every catalogue query."
  def active, do: from(p in Product, where: is_nil(p.deleted_at))

  @doc "The stock level at or below which a product is low on stock."
  def low_stock, do: @low_stock

  @doc "How many products are out of stock and how many are low (but not out)."
  def stock_alerts do
    from(p in active(),
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
    active()
    |> apply_filters(filters)
    |> sort(filters["sort"])
    |> Repo.all()
  end

  @doc "One page of the catalogue, newest first: `limit` products after the first `offset`."
  def page_products(offset, limit) do
    active()
    |> sort("newest")
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "How many products the catalogue holds."
  def count_products, do: Repo.aggregate(active(), :count)

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
      | active()
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
    active()
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
      {:ok, id} when id in 1..@max_id -> active() |> Repo.get!(id) |> Repo.preload(:variants)
      _ -> raise Ecto.NoResultsError, queryable: Product
    end
  end

  @doc "Like `get_product!/1`, but `nil` when there is no such product (or the id is not one)."
  def get_product(id) do
    get_product!(id)
  rescue
    Ecto.NoResultsError -> nil
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
    changeset = Product.changeset(%Product{variants: []}, attrs)

    Repo.transaction(fn ->
      Repo.query!("SELECT pg_advisory_xact_lock($1)", [@create_lock])

      case changeset |> check_catalogue_limit() |> Repo.insert() do
        {:ok, product} -> product
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    |> log_event("created", nil)
    |> notify_subscribers(:product_created)
  end

  defp check_catalogue_limit(changeset) do
    if catalogue_full?() do
      Ecto.Changeset.add_error(
        changeset,
        :base,
        "The demo is limited to %{max} products",
        max: @max_products
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

      count_products() + creates > @max_products ->
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
      # with its variants, so an imported stock can't contradict them
      {:ok, id} when id in 1..@max_id -> active() |> Repo.get(id) |> Repo.preload(:variants)
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
    |> Repo.preload(:variants)
    |> Product.changeset(attrs)
    |> Repo.update()
    |> log_event("updated", product)
    |> notify_subscribers(:product_updated)
  end

  @restock_amount 10

  @doc "How many items one restock adds."
  def restock_amount, do: @restock_amount

  @doc """
  Adds #{@restock_amount} to a product's stock, capped at the largest stock a product may have;
  with variants, to the variant with the least stock. The increments run in the database,
  so two restocks at once both count.
  """
  def restock_product(%Product{id: id} = product) do
    max = Product.max_amount()

    Repo.transaction(fn ->
      variant_restocked? =
        Repo.update_all(
          from(v in Variant,
            where:
              v.id ==
                subquery(
                  from(v in Variant,
                    where: v.product_id == ^id,
                    order_by: [asc: v.stock, asc: v.id],
                    limit: 1,
                    select: v.id
                  )
                )
          ),
          inc: [stock: @restock_amount]
        )
        |> elem(0) == 1

      new_stock =
        if variant_restocked?,
          do:
            dynamic(
              [p],
              fragment("(SELECT sum(stock) FROM product_variants WHERE product_id = ?)", p.id)
            ),
          else: dynamic([p], fragment("LEAST(? + ?, ?)", p.stock, ^@restock_amount, ^max))

      from(p in active(), where: p.id == ^id, select: p, update: [set: [stock: ^new_stock]])
      |> Repo.update_all(set: [updated_at: DateTime.utc_now(:second)])
      |> case do
        {1, [restocked]} -> restocked
        {0, []} -> Repo.rollback(:not_found)
      end
    end)
    |> case do
      {:ok, restocked} ->
        {:ok, restocked}
        |> log_event("restocked", product)
        |> notify_subscribers(:product_updated)

      {:error, :not_found} ->
        {:error, :not_found}
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
    product
    |> Ecto.Changeset.change(deleted_at: DateTime.utc_now(:second))
    |> Repo.update()
    |> log_event("deleted", product)
    |> notify_subscribers(:product_deleted)
  end

  @purge_after_minutes 10

  @doc "How long a deleted product can be restored."
  def purge_after_minutes, do: @purge_after_minutes

  @doc """
  Brings back a product deleted less than #{@purge_after_minutes} minutes ago, if the
  catalogue has room for it.
  """
  def restore_product(id) do
    with {:ok, id} when id in 1..@max_id <- Ecto.Type.cast(:id, id),
         %Product{deleted_at: %DateTime{}} = product <- Repo.get(Product, id),
         false <- catalogue_full?() do
      product
      |> Ecto.Changeset.change(deleted_at: nil)
      |> Repo.update()
      |> log_event("restored", product)
      |> notify_subscribers(:product_created)
    else
      true -> {:error, :catalogue_full}
      _ -> {:error, :not_found}
    end
  end

  @doc "Deletes for good the products deleted more than `minutes` ago, with their sales."
  def purge_deleted(minutes \\ @purge_after_minutes) do
    cutoff = DateTime.add(DateTime.utc_now(), -minutes, :minute)
    {count, _} = Repo.delete_all(from(p in Product, where: p.deleted_at < ^cutoff))
    count
  end

  @doc "A product's versions, newest first."
  def list_versions(product_id, limit \\ 30) do
    Version
    |> where([v], v.product_id == ^product_id)
    |> order_by(desc: :inserted_at, desc: :id)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  The prices a product had, newest first, as `{price, since}`, from its versions
  (newest first): the first version and each change of the price.
  """
  def price_history(versions) do
    for %Version{} = version <- Enum.reverse(versions),
        version.action == "created" or Map.has_key?(version.changes, "price"),
        reduce: [] do
      history ->
        [{Decimal.new(to_string(version.snapshot["price"])), version.inserted_at} | history]
    end
  end

  @doc "Puts back a version's title, description, category, price, tags and photo (not the stock)."
  def revert_to_version(%Product{} = product, version_id) do
    with {:ok, version_id} <- Ecto.Type.cast(:id, version_id),
         %Version{snapshot: snapshot} <-
           Repo.get_by(Version, id: version_id, product_id: product.id) do
      update_product(product, Map.take(snapshot, @revertable))
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    product |> Repo.preload(:variants) |> Product.changeset(attrs)
  end

  # the feed gets every event; the history gets each state the product was in
  defp log_event({:ok, product} = result, kind, before) do
    changes =
      if kind in ["updated", "restocked"], do: ActivityFeed.changes(before, product), else: %{}

    ActivityFeed.product_event(kind, product, changes)

    if kind != "deleted" and (kind != "updated" or changes != %{}) do
      Repo.insert!(%Version{
        product_id: product.id,
        action: kind,
        snapshot:
          product |> Map.take(@snapshot_fields) |> Map.new(fn {k, v} -> {to_string(k), v} end),
        changes: changes
      })
    end

    result
  end

  defp log_event(error, _kind, _before), do: error

  defp notify_subscribers({:ok, product}, event) do
    Phoenix.PubSub.broadcast(ClothingStore.PubSub, "products", {event, product})
    {:ok, product}
  end

  defp notify_subscribers(error, _event), do: error
end
