defmodule ClothingStoreWeb.Helpers do
  def active_class(conn, route_name) do
    if current_route(conn) == route_name do
      "active"
    else
      ""
    end
  end

  defp current_route(conn) do
    conn.path_info
    |> Enum.join("/")
    |> String.to_atom()
  end

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
end
