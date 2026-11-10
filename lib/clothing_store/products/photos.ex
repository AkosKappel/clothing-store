defmodule ClothingStore.Products.Photos do
  @moduledoc """
  Uploaded product photos. Each upload is decoded and re-encoded to WebP by libvips,
  so what is served is always a fresh image without metadata (no GPS, no hidden payload),
  at most 1600px on its longer side. Files get random names in the uploads
  directory, which the nightly reset empties.
  """

  alias Vix.Vips.{Image, Operation}

  @max_side 1600
  # bounds the memory a decode can take; a 40 MP photo is already larger than phones take
  @max_pixels 40_000_000
  # the uploads only live until the nightly reset; this keeps one day of abuse small
  @max_files 300

  @doc "The directory uploaded photos are stored in and served from (`/uploads/...`)."
  def dir, do: Application.fetch_env!(:clothing_store, :uploads_dir)

  @doc "Whether `path` is the public path of a stored upload, as `store/1` returns them."
  def upload_path?(path), do: Regex.match?(~r"\A/uploads/[0-9a-f]{32}\.webp\z", path)

  @doc """
  Re-encodes a JPEG, PNG or WebP image and stores it. Returns `{:ok, public_path}` or
  `{:error, reason}`, where reason is `:not_an_image`, `:full`, `:too_large` or `:unreadable`.
  """
  # the directory is configuration and the name random hex: nothing comes from the visitor
  # sobelow_skip ["Traversal.FileModule"]
  def store(binary) when is_binary(binary) do
    with :ok <- check_type(binary),
         :ok <- check_room(),
         {:ok, webp} <- reencode(binary) do
      name = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower) <> ".webp"
      File.mkdir_p!(dir())
      File.write!(Path.join(dir(), name), webp)
      {:ok, "/uploads/" <> name}
    end
  end

  @doc "Deletes every stored upload."
  def clear do
    File.rm_rf!(dir())
    :ok
  end

  # by content, not by the name or type the browser claims
  defp check_type(<<0xFF, 0xD8, 0xFF, _::binary>>), do: :ok
  defp check_type(<<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: :ok
  defp check_type(<<"RIFF", _size::binary-size(4), "WEBP", _::binary>>), do: :ok
  defp check_type(_binary), do: {:error, :not_an_image}

  defp check_room do
    case File.ls(dir()) do
      {:ok, files} when length(files) >= @max_files ->
        {:error, :full}

      _ ->
        :ok
    end
  end

  defp reencode(binary) do
    # new_from_buffer reads only the header, so the size is checked before decoding
    with {:ok, header} <- Image.new_from_buffer(binary),
         true <- Image.width(header) * Image.height(header) <= @max_pixels,
         {:ok, image} <-
           Operation.thumbnail_buffer(binary, @max_side, height: @max_side, size: :VIPS_SIZE_DOWN),
         {:ok, webp} <- Image.write_to_buffer(image, ".webp[Q=80,strip]") do
      {:ok, webp}
    else
      false -> {:error, :too_large}
      {:error, _reason} -> {:error, :unreadable}
    end
  end
end
