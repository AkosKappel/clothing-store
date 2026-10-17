defmodule ClothingStore.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  alias ClothingStore.Products.Variant

  schema "products" do
    field :description, :string
    field :title, :string
    field :category, :string
    field :photo, :string
    field :price, :decimal
    field :stock, :integer
    field :tags, {:array, :string}, default: []
    field :deleted_at, :utc_datetime
    field :discount_percent, :integer
    field :discount_starts_on, :date
    field :discount_ends_on, :date

    has_many :variants, Variant,
      on_replace: :delete,
      preload_order: [asc: :id]

    has_many :products_transactions, ClothingStore.Products.ProductTransaction
    has_many :transactions, through: [:products_transactions, :transaction]

    timestamps(type: :utc_datetime)
  end

  @max_amount 100_000
  @max_variants 12
  @max_tags 10
  @max_tag_length 30
  @max_tag_bytes 120
  # remote photos must come from these hosts; the CSP img-src lists the same ones
  @photo_hosts ~w(images.pexels.com images.unsplash.com)

  @doc "The highest price and stock a product may have."
  def max_amount, do: @max_amount

  @doc "Hosts that product photos may be loaded from."
  def photo_hosts, do: @photo_hosts

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :photo,
      :title,
      :description,
      :category,
      :price,
      :stock,
      :tags,
      :discount_percent,
      :discount_starts_on,
      :discount_ends_on
    ])
    |> validate_required([:photo, :title, :description, :category, :price, :stock])
    |> validate_length(:title, max: 100)
    |> validate_length(:category, max: 50)
    |> validate_length(:description, max: 2000)
    # graphemes can carry any number of combining marks, so bound the stored size too
    |> validate_length(:title, max: 400, count: :bytes)
    |> validate_length(:category, max: 200, count: :bytes)
    |> validate_length(:description, max: 8000, count: :bytes)
    # photos are ASCII paths/URLs; bytes alone bound them
    |> validate_length(:photo, max: 500, count: :bytes)
    |> validate_photo()
    |> validate_tags()
    |> validate_number(:price, greater_than_or_equal_to: 0, less_than_or_equal_to: @max_amount)
    |> validate_number(:stock, greater_than_or_equal_to: 0, less_than_or_equal_to: @max_amount)
    |> validate_discount()
    |> cast_assoc(:variants,
      with: &Variant.changeset/2,
      sort_param: :variants_sort,
      drop_param: :variants_drop
    )
    |> validate_length(:variants, max: @max_variants, message: "can be at most %{count}")
    |> total_variant_stock()
  end

  # with variants, the product's stock is their total and can't be set on its own
  defp total_variant_stock(changeset) do
    variants =
      case fetch_change(changeset, :variants) do
        {:ok, _changes} ->
          get_assoc(changeset, :variants, :struct)

        :error ->
          if Ecto.assoc_loaded?(changeset.data.variants), do: changeset.data.variants, else: []
      end

    if variants == [],
      do: changeset,
      else: put_change(changeset, :stock, variants |> Enum.map(&(&1.stock || 0)) |> Enum.sum())
  end

  # a discount needs all three fields, and the end can't come before the start
  defp validate_discount(changeset) do
    if get_field(changeset, :discount_percent) do
      changeset
      |> validate_number(:discount_percent, greater_than: 0, less_than_or_equal_to: 90)
      |> validate_required([:discount_starts_on, :discount_ends_on],
        message: "is needed for a discount"
      )
      |> validate_change(:discount_ends_on, &validate_ends_on(&1, &2, changeset))
    else
      changeset
    end
  end

  defp validate_ends_on(:discount_ends_on, ends_on, changeset) do
    starts_on = get_field(changeset, :discount_starts_on)

    if starts_on && Date.before?(ends_on, starts_on),
      do: [discount_ends_on: "can't be before the start"],
      else: []
  end

  @doc "Whether the product's discount runs on `date`."
  def on_sale?(%__MODULE__{discount_percent: percent} = product, date \\ Date.utc_today()) do
    is_integer(percent) and not is_nil(product.discount_starts_on) and
      not is_nil(product.discount_ends_on) and
      not Date.before?(date, product.discount_starts_on) and
      not Date.after?(date, product.discount_ends_on)
  end

  @doc "The price a customer pays on `date`: the list price less any running discount."
  def sale_price(%__MODULE__{price: price} = product, date \\ Date.utc_today()) do
    if on_sale?(product, date),
      do:
        price
        |> Decimal.mult(100 - product.discount_percent)
        |> Decimal.div(100)
        |> Decimal.round(2),
      else: price
  end

  defp validate_photo(changeset) do
    validate_change(changeset, :photo, fn :photo, photo ->
      if allowed_photo?(photo),
        do: [],
        else: [
          photo:
            {"must be a path under /images/ or an https:// URL from %{hosts}",
             hosts: photo_hosts_text()}
        ]
    end)
  end

  @doc false
  def photo_hosts_text, do: Enum.join(@photo_hosts, ", ")

  defp allowed_photo?("/images/" <> _ = path),
    # "%2e%2e" is a dot-segment to browsers too
    do: not String.contains?(String.downcase(path), ["..", "%2e", "\\"])

  defp allowed_photo?("https://" <> _ = url) do
    case URI.new(url) do
      {:ok, %URI{scheme: "https", host: host, port: 443, userinfo: nil}} ->
        String.downcase(host) in @photo_hosts

      _ ->
        false
    end
  end

  defp allowed_photo?(_), do: false

  defp validate_tags(changeset) do
    validate_change(changeset, :tags, fn :tags, tags ->
      cond do
        length(tags) > @max_tags ->
          [tags: {"should have at most %{max} tags", max: @max_tags}]

        Enum.any?(tags, &(String.length(&1) not in 1..@max_tag_length)) ->
          [tags: {"each tag should be 1 to %{max} characters", max: @max_tag_length}]

        Enum.any?(tags, &(byte_size(&1) > @max_tag_bytes)) ->
          [tags: {"each tag should be at most %{max} bytes", max: @max_tag_bytes}]

        true ->
          []
      end
    end)
  end
end
