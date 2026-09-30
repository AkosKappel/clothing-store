defmodule ClothingStore.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, :string
    field :title, :string
    field :category, :string
    field :photo, :string
    field :price, :decimal
    field :stock, :integer
    field :tags, {:array, :string}, default: []

    has_many :products_transactions, ClothingStore.Products.ProductTransaction
    has_many :transactions, through: [:products_transactions, :transaction]

    timestamps(type: :utc_datetime)
  end

  @max_amount 100_000
  @max_tags 10
  @max_tag_length 30
  @max_tag_bytes 120
  # remote photos must come from these hosts; the CSP img-src lists the same ones
  @photo_hosts ~w(images.pexels.com images.unsplash.com)

  @doc "Hosts that product photos may be loaded from."
  def photo_hosts, do: @photo_hosts

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:photo, :title, :description, :category, :price, :stock, :tags])
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
  end

  defp validate_photo(changeset) do
    validate_change(changeset, :photo, fn :photo, photo ->
      if allowed_photo?(photo),
        do: [],
        else: [
          photo: "must be a path under /images/ or an https:// URL from #{photo_hosts_text()}"
        ]
    end)
  end

  @doc false
  def photo_hosts_text, do: Enum.join(@photo_hosts, " or ")

  defp allowed_photo?("/images/" <> _ = path),
    # "%2e%2e" is a dot-segment to browsers too
    do: not String.contains?(String.downcase(path), ["..", "%2e", "\\"])

  defp allowed_photo?("https://" <> _ = url) do
    case URI.new(url) do
      {:ok, %URI{scheme: "https", host: host, port: 443, userinfo: nil}} -> host in @photo_hosts
      _ -> false
    end
  end

  defp allowed_photo?(_), do: false

  defp validate_tags(changeset) do
    validate_change(changeset, :tags, fn :tags, tags ->
      cond do
        length(tags) > @max_tags ->
          [tags: "should have at most #{@max_tags} tags"]

        Enum.any?(tags, &(String.length(&1) not in 1..@max_tag_length)) ->
          [tags: "each tag should be 1 to #{@max_tag_length} characters"]

        Enum.any?(tags, &(byte_size(&1) > @max_tag_bytes)) ->
          [tags: "each tag should be at most #{@max_tag_bytes} bytes"]

        true ->
          []
      end
    end)
  end
end
