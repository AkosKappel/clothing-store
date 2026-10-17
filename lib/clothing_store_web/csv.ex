defmodule ClothingStoreWeb.CSV do
  @moduledoc "RFC 4180 CSV for the exports and the inventory import, safe to open in a spreadsheet."

  @doc """
  Encodes rows (lists of values) as CSV with CRLF line endings.

  Text starting with `=`, `+`, `-`, `@`, a tab or a carriage return gets a
  leading `'`, so a product title typed by a visitor can't run as a
  spreadsheet formula. Numbers are written as they are.
  """
  def encode(rows),
    do: Enum.map_join(rows, &[Enum.map_join(&1, ",", fn v -> field(v) end), "\r\n"])

  @doc """
  Parses CSV into rows of strings: quoted fields, doubled quotes, CRLF or LF line
  endings and a UTF-8 byte order mark are understood; blank lines are skipped.
  Returns `:error` for an unterminated quote.
  """
  def decode(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: decode(rest)
  def decode(csv) when is_binary(csv), do: parse(csv, "", [], [])

  defp parse(<<?", rest::binary>>, "", row, rows), do: quoted(rest, "", row, rows)
  defp parse(<<?,, rest::binary>>, field, row, rows), do: parse(rest, "", [field | row], rows)

  defp parse(<<"\r\n", rest::binary>>, field, row, rows),
    do: parse(rest, "", [], add_row(field, row, rows))

  defp parse(<<?\n, rest::binary>>, field, row, rows),
    do: parse(rest, "", [], add_row(field, row, rows))

  defp parse(<<c::utf8, rest::binary>>, field, row, rows),
    do: parse(rest, <<field::binary, c::utf8>>, row, rows)

  defp parse(<<_invalid, rest::binary>>, field, row, rows), do: parse(rest, field, row, rows)
  defp parse("", field, row, rows), do: {:ok, Enum.reverse(add_row(field, row, rows))}

  defp quoted(<<?", ?", rest::binary>>, field, row, rows),
    do: quoted(rest, field <> ~s("), row, rows)

  # after the closing quote the field continues unquoted until , or a line end
  defp quoted(<<?", rest::binary>>, field, row, rows), do: parse(rest, field, row, rows)

  defp quoted(<<c::utf8, rest::binary>>, field, row, rows),
    do: quoted(rest, <<field::binary, c::utf8>>, row, rows)

  defp quoted(<<_invalid, rest::binary>>, field, row, rows), do: quoted(rest, field, row, rows)
  defp quoted("", _field, _row, _rows), do: :error

  defp add_row("", [], rows), do: rows
  defp add_row(field, row, rows), do: [Enum.reverse([field | row]) | rows]

  @doc "Undoes the formula guard of `encode/1`: `'=SUM(1)` reads back as `=SUM(1)`."
  def unguard(<<?', first, _::binary>> = value) when first in ~c"=+-@\t\r",
    do: binary_part(value, 1, byte_size(value) - 1)

  def unguard(value), do: value

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
