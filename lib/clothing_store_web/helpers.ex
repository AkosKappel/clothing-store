defmodule ClothingStoreWeb.Helpers do
  @moduledoc "Formatting helpers shared by templates: prices, dates and password rules."

  alias ClothingStore.Users.User

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

  @doc "The password rules as `{label, met?}` pairs, for `CoreComponents.requirements/1`."
  def password_requirements(password, confirmation) do
    password = password || ""
    min_length = User.password_min_length()

    [
      {"At least #{min_length} characters", String.length(password) >= min_length},
      {"Both passwords match", password != "" and password == confirmation}
    ]
  end

  @doc """
  A rough strength score for a new password, 0 (empty) to 4: length counts most,
  then the mix of lower case, upper case, digits and symbols.
  """
  def password_score(password) when password in [nil, ""], do: 0

  def password_score(password) do
    length = String.length(password)

    classes =
      Enum.count([~r/\p{Ll}/u, ~r/\p{Lu}/u, ~r/\d/, ~r/[^\p{L}\d]/u], &Regex.match?(&1, password))

    score =
      Enum.count(
        [length >= User.password_min_length(), length >= 16, classes >= 2, classes >= 3],
        & &1
      )

    max(score, 1)
  end

  # photo is required and validated (local /images/ path or allowlisted host)
  def image_link(image_path), do: image_path

  @doc """
  A `"YYYY-MM"` query param as `{param, first_day_of_month}`; anything else is
  `{nil, nil}`, meaning every month.
  """
  def parse_month(month) when is_binary(month) do
    with true <- Regex.match?(~r/^\d{4}-\d{2}$/, month),
         {:ok, date} <- Date.from_iso8601(month <> "-01") do
      {month, date}
    else
      _ -> {nil, nil}
    end
  end

  def parse_month(_month), do: {nil, nil}

  def current_path(assigns) do
    cond do
      # LiveViews, see ClothingStoreWeb.CurrentPath
      assigns[:current_path] -> assigns.current_path
      assigns[:conn] -> assigns.conn.request_path
      true -> "/"
    end
  end
end
