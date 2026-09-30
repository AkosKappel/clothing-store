defmodule ClothingStoreWeb.Helpers do
  def format_price(price) when is_nil(price), do: "0,00 €"

  def format_price(price) do
    price
    |> Decimal.round(2)
    |> Decimal.to_string()
    |> String.replace(".", ",")
    |> Kernel.<>(" €")
  end

  def format_date(nil), do: "-"

  def format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.replace("T", " ")
    |> String.slice(0..18)
  end

  # photo is required and validated (local /images/ path or allowlisted host)
  def image_link(image_path), do: image_path

  def current_path(assigns) do
    cond do
      # For LiveView pages
      assigns[:live_action] -> "/" <> Atom.to_string(assigns.live_action)
      # For regular controller pages
      assigns[:conn] -> assigns.conn.request_path
      true -> "/"
    end
  end
end
