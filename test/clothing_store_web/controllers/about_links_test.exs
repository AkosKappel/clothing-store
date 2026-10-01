defmodule ClothingStoreWeb.AboutLinksTest do
  # changes the :demo application env, so it can't run next to other tests
  use ClothingStoreWeb.ConnCase, async: false

  setup do
    original = Application.fetch_env!(:clothing_store, :demo)
    on_exit(fn -> Application.put_env(:clothing_store, :demo, original) end)
    %{original: original}
  end

  defp put_links(original, links) do
    Application.put_env(:clothing_store, :demo, Keyword.put(original, :links, links))
  end

  test "an empty portfolio link is not rendered", %{conn: conn, original: original} do
    put_links(original, github: "https://github.example.com/me", portfolio: "")

    html = conn |> get(~p"/about") |> html_response(200)

    assert html =~ ~s(href="https://github.example.com/me")
    refute html =~ "Portfolio"
  end

  test "a configured portfolio link is rendered", %{conn: conn, original: original} do
    put_links(original, portfolio: "https://portfolio.example.com")

    html = conn |> get(~p"/about") |> html_response(200)

    assert html =~ ~s(href="https://portfolio.example.com")
    assert html =~ "Portfolio"
  end

  test "without a repository link there is no source code button", %{
    conn: conn,
    original: original
  } do
    put_links(original, github: "https://github.example.com/me")

    html = conn |> get(~p"/about") |> html_response(200)

    refute html =~ "View source code"
    refute html =~ "Source code of this project"
  end

  test "the repository link is the source code button", %{conn: conn, original: original} do
    put_links(original, repository: "https://example.com/repo")

    html = conn |> get(~p"/about") |> html_response(200)

    assert html =~ "View source code"
    assert html =~ "Source code of this project"
  end
end
