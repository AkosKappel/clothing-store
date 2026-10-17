defmodule ClothingStoreWeb.LocaleTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "?locale= sets the cookie and redirects back without the parameter", %{conn: conn} do
    conn = get(conn, "/about?locale=de&x=1")

    assert redirected_to(conn) == "/about?x=1"
    assert conn.resp_cookies["locale"].value == "de"
  end

  test "an unknown locale is ignored", %{conn: conn} do
    conn = conn |> put_req_cookie("locale", "xx") |> get(~p"/users/log_in?locale=fr")

    assert html_response(conn, 200) =~ ~s(<html lang="en")
  end

  test "the cookie picks the language of pages and LiveViews", %{conn: conn} do
    conn = put_req_cookie(conn, "locale", "de")

    assert conn |> get(~p"/users/log_in") |> html_response(200) =~ ~s(<html lang="de")

    {:ok, _lv, html} = live(conn, ~p"/users/log_in")
    assert html =~ "Demo ausprobieren"

    {:ok, _lv, html} = conn |> put_req_cookie("locale", "sk") |> live(~p"/users/log_in")
    assert html =~ "Vyskúšať demo"
  end
end
