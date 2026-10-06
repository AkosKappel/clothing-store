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

  @doc """
  How long ago `datetime` was, for recent dates ("just now", "5 min ago",
  "3 hours ago", "yesterday", "4 days ago"); the date itself after a week.
  """
  def relative_time(%DateTime{} = datetime, now \\ DateTime.utc_now()) do
    seconds = DateTime.diff(now, datetime)

    cond do
      seconds < 60 -> "just now"
      seconds < 3600 -> "#{div(seconds, 60)} min ago"
      seconds < 2 * 3600 -> "1 hour ago"
      seconds < 86_400 -> "#{div(seconds, 3600)} hours ago"
      seconds < 2 * 86_400 -> "yesterday"
      seconds < 7 * 86_400 -> "#{div(seconds, 86_400)} days ago"
      true -> datetime |> DateTime.to_date() |> Date.to_iso8601()
    end
  end

  # photo is required and validated (local /images/ path or allowlisted host)
  def image_link(image_path), do: image_path

  def current_path(assigns) do
    cond do
      # LiveViews, see ClothingStoreWeb.CurrentPath
      assigns[:current_path] -> assigns.current_path
      assigns[:conn] -> assigns.conn.request_path
      true -> "/"
    end
  end
end
