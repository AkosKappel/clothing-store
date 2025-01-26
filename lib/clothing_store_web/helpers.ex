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

  def current_path(assigns) do
    cond do
      assigns[:live_action] -> "/" <> Atom.to_string(assigns.live_action)  # For LiveView pages
      assigns[:conn] -> assigns.conn.request_path  # For regular controller pages
      true -> "/"
    end
  end
end
