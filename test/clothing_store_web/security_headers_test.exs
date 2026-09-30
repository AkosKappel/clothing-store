defmodule ClothingStoreWeb.SecurityHeadersTest do
  use ClothingStoreWeb.ConnCase, async: true

  @csp "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " <>
         "img-src 'self' data: https://images.pexels.com https://images.unsplash.com; " <>
         "font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self'; " <>
         "form-action 'self'; frame-ancestors 'self'"

  test "browser pages send a single, strict content security policy", %{conn: conn} do
    conn = get(conn, ~p"/users/log_in")
    assert get_resp_header(conn, "content-security-policy") == [@csp]
  end

  describe "logged in" do
    setup :register_and_log_in_user

    test "the app layout has no inline scripts", %{conn: conn} do
      html = conn |> get(~p"/products") |> html_response(200)
      assert html =~ ~s(id="menu-toggle")

      scripts = Regex.scan(~r/<script\b[^>]*>/, html) |> List.flatten()
      assert scripts != []
      assert Enum.all?(scripts, &(&1 =~ ~r/\ssrc=/)), inspect(scripts)
      refute html =~ ~r/\son[a-z]+=/
    end
  end
end
