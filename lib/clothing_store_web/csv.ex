defmodule ClothingStoreWeb.CSV do
  @moduledoc "Builds RFC 4180 CSV for the exports, safe to open in a spreadsheet."

  @doc """
  Encodes rows (lists of values) as CSV with CRLF line endings.

  Text starting with `=`, `+`, `-`, `@`, a tab or a carriage return gets a
  leading `'`, so a product title typed by a visitor can't run as a
  spreadsheet formula. Numbers are written as they are.
  """
  def encode(rows),
    do: Enum.map_join(rows, &[Enum.map_join(&1, ",", fn v -> field(v) end), "\r\n"])

  defp field(nil), do: ""
  defp field(value) when is_number(value), do: to_string(value)
  defp field(%Decimal{} = value), do: Decimal.to_string(value, :normal)
  defp field(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp field(value) when is_binary(value), do: value |> neutralize() |> escape()

  defp neutralize(<<first, _::binary>> = value) when first in ~c"=+-@\t\r", do: "'" <> value
  defp neutralize(value), do: value

  defp escape(value) do
    if String.contains?(value, [",", "\"", "\r", "\n"]),
      do: ~s(") <> String.replace(value, ~s("), ~s("")) <> ~s("),
      else: value
  end
end
