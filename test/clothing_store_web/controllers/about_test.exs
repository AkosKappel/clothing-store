defmodule ClothingStoreWeb.AboutTest do
  use ClothingStoreWeb.ConnCase, async: true

  @h1 "A stock dashboard for a clothing shop, built while learning its stack"
  @tasks [
    "Product dashboard",
    "Inventory, transactions and statistics",
    "Login",
    "Live feed",
    "Tags",
    "Tag filter"
  ]

  defp button(text, href), do: ~r/<a href="#{Regex.escape(href)}"[^>]*>\s*#{text}\s*</

  defp header(html) do
    [header] = Regex.run(~r/<header.*?<\/header>/s, html)
    header
  end

  describe "GET /about logged out" do
    test "is public and explains the project", %{conn: conn} do
      html = conn |> get(~p"/about") |> html_response(200)

      assert html =~ @h1
      assert html =~ ~r/<title[^>]*>\s*About\s*\| Modern Fashion Store<\/title>/
      assert html =~ button("Try the demo", "/users/log_in")
      refute html =~ ~r/>\s*Open the dashboard\s*</
      reset = ClothingStore.Demo.reset_settings()
      assert html =~ Calendar.strftime(reset.time, "%H:%M")
      assert html =~ "#{reset.timezone} time"
      for task <- @tasks, do: assert(html =~ task)
      assert html =~ ClothingStore.Demo.author()
    end

    test "the header offers About and Log in but no dashboard links", %{conn: conn} do
      header = conn |> get(~p"/about") |> html_response(200) |> header()

      assert header =~ ~s(href="/about")
      assert header =~ ~s(href="/users/log_in")
      refute header =~ "Inventory"
      refute header =~ "Transactions"
      refute header =~ "Log out"
    end

    test "external links open in a new tab without an opener", %{conn: conn} do
      html = conn |> get(~p"/about") |> html_response(200)

      links = Regex.scan(~r/<a\b[^>]*href="https?:[^"]*"[^>]*>/, html) |> List.flatten()
      assert links != []

      for link <- links do
        assert link =~ ~s(target="_blank"), link
        assert link =~ ~s(rel="noopener noreferrer"), link
      end
    end

    test "has no inline scripts, styles or handlers", %{conn: conn} do
      html = conn |> get(~p"/about") |> html_response(200)

      scripts = Regex.scan(~r/<script\b[^>]*>/, html) |> List.flatten()
      assert Enum.all?(scripts, &(&1 =~ ~r/\ssrc=/)), inspect(scripts)
      refute html =~ ~r/\son[a-z]+=/
      refute html =~ ~r/\sstyle=/
    end
  end

  describe "GET /about logged in" do
    setup :register_and_log_in_user

    test "links to the dashboard and shows the dashboard nav", %{conn: conn} do
      html = conn |> get(~p"/about") |> html_response(200)

      assert html =~ button("Open the dashboard", "/")
      refute html =~ "Try the demo"

      header = header(html)
      assert header =~ "Inventory"
      assert header =~ "Transactions"
      assert header =~ "Statistics"
      assert header =~ "Log out"
      assert header =~ ~s(href="/about")
      refute header =~ ~s(href="/users/log_in")
    end
  end
end
