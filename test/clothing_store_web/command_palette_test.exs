defmodule ClothingStoreWeb.CommandPaletteTest do
  use ClothingStoreWeb.ConnCase, async: true

  test "logged-in pages carry the command palette", %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    html = conn |> get(~p"/products") |> html_response(200)

    assert html =~ ~s(id="command-palette")
    assert html =~ ~s(href="/transactions")
  end

  test "visitors don't get it", %{conn: conn} do
    refute conn |> get(~p"/about") |> html_response(200) =~ ~s(id="command-palette")
  end
end
