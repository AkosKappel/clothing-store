defmodule ClothingStoreWeb.InfoPagesTest do
  use ClothingStoreWeb.ConnCase, async: true

  test "privacy page is public and names every cookie", %{conn: conn} do
    html = conn |> get(~p"/privacy") |> html_response(200)

    assert html =~ ~r/<title[^>]*>\s*Privacy\s*\| Modern Fashion Store<\/title>/

    for cookie <- ~w(_clothing_store_key _clothing_store_web_user_remember_me welcome_seen),
        do: assert(html =~ cookie)
  end

  test "terms page is public and states the product cap", %{conn: conn} do
    html = conn |> get(~p"/terms") |> html_response(200)

    assert html =~ "Terms of use"
    assert html =~ "at most #{ClothingStore.Products.max_products()} products"
  end

  test "the footer links both pages", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)

    assert html =~ ~s(href="/privacy")
    assert html =~ ~s(href="/terms")
  end

  test "pages carry a description and a link preview image", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)

    assert html =~ ~r/<meta name="description" content="[^"]+"/
    assert html =~ ~r{<meta property="og:image" content="http[^"]+/images/og-image.jpg"}
  end

  test "the app is installable: manifest, service worker and offline page", %{conn: conn} do
    html = conn |> get(~p"/about") |> html_response(200)
    assert html =~ ~s(rel="manifest")

    manifest = conn |> get("/manifest.webmanifest") |> response(200) |> Jason.decode!()
    assert manifest["display"] == "standalone"
    assert Enum.map(manifest["icons"], & &1["sizes"]) == ["192x192", "512x512"]

    assert build_conn() |> get("/sw.js") |> response(200) =~ "offline.html"
    assert build_conn() |> get("/offline.html") |> response(200) =~ "You're offline"
  end

  test "the theme cookie picks the theme on the server, so pages never flash", %{conn: conn} do
    assert conn |> get(~p"/about") |> html_response(200) =~
             ~r/<html lang="en" class="\[scrollbar-gutter:stable\]\s*">/

    for theme <- ~w(dark light) do
      html =
        build_conn() |> put_req_cookie("theme", theme) |> get(~p"/about") |> html_response(200)

      assert html =~ ~s(class="[scrollbar-gutter:stable] #{theme}")
    end

    html =
      build_conn() |> put_req_cookie("theme", "<script>") |> get(~p"/about") |> html_response(200)

    refute html =~ "<script>\""
  end
end
