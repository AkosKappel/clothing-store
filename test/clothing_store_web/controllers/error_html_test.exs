defmodule ClothingStoreWeb.ErrorHTMLTest do
  use ClothingStoreWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders a styled 404 page with a way back" do
    html = render_to_string(ClothingStoreWeb.ErrorHTML, "404", "html", [])

    assert html =~ "<title>Page not found | Modern Fashion Store</title>"
    assert html =~ ~s(href="/")
    refute html =~ "Reference:"
  end

  test "renders a styled 500 page with the request id as reference" do
    Logger.metadata(request_id: "F1a2B3c4")

    html = render_to_string(ClothingStoreWeb.ErrorHTML, "500", "html", [])

    assert html =~ "Something went wrong"
    assert html =~ "F1a2B3c4"
  end

  test "other statuses keep the plain text message" do
    assert render_to_string(ClothingStoreWeb.ErrorHTML, "403", "html", []) == "Forbidden"
  end
end
