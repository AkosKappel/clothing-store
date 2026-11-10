defmodule ClothingStore.PhotosTest do
  # one uploads directory for the whole run
  use ExUnit.Case, async: false

  alias ClothingStore.Products.Photos
  alias Vix.Vips.{Image, MutableImage, Operation}

  setup do
    Photos.clear()
    on_exit(&Photos.clear/0)
  end

  # a JPEG carrying EXIF metadata, as phones write them
  defp jpeg_with_exif(width \\ 2400, height \\ 1200) do
    {:ok, image} = Operation.black(width, height, bands: 3)

    {:ok, image} =
      Image.mutate(
        image,
        &MutableImage.set(&1, "exif-ifd0-Artist", :gchararray, "Someone")
      )

    {:ok, jpeg} = Image.write_to_buffer(image, ".jpg")
    jpeg
  end

  test "stores a re-encoded, shrunk WebP without metadata under a random name" do
    jpeg = jpeg_with_exif()
    assert jpeg =~ "Exif"

    assert {:ok, "/uploads/" <> name = path} = Photos.store(jpeg)
    assert Photos.upload_path?(path)

    webp = File.read!(Path.join(Photos.dir(), name))
    assert <<"RIFF", _::binary-size(4), "WEBP", _::binary>> = webp
    refute webp =~ "Exif"
    {:ok, stored} = Image.new_from_buffer(webp)
    assert {Image.width(stored), Image.height(stored)} == {1600, 800}
  end

  test "judges files by their content, not their name" do
    assert Photos.store("<svg onload=alert(1)>") == {:error, :not_an_image}
    assert Photos.store(<<0xFF, 0xD8, 0xFF, "not really a jpeg">>) == {:error, :unreadable}
  end

  test "clear/0 removes every upload" do
    {:ok, "/uploads/" <> name} = Photos.store(jpeg_with_exif(10, 10))
    assert :ok = Photos.clear()
    refute File.exists?(Path.join(Photos.dir(), name))
  end

  test "only paths store/1 makes count as uploads" do
    refute Photos.upload_path?("/uploads/../secret.webp")
    refute Photos.upload_path?("/uploads/abc.svg")
    assert Photos.upload_path?("/uploads/" <> String.duplicate("a1", 16) <> ".webp")
  end
end
