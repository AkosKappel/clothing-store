defmodule ClothingStoreWeb.UserLoginLiveTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ClothingStore.UsersFixtures

  alias ClothingStore.Demo

  describe "Log in page" do
    test "offers the demo without putting its credentials in the page", %{conn: conn} do
      user_fixture(Demo.account())
      {:ok, lv, html} = live(conn, ~p"/users/log_in")

      assert has_element?(
               lv,
               ~s|form[action="/users/demo_log_in"] button:not([disabled])|,
               "Try the demo"
             )

      assert html =~ "resets every night"
      refute html =~ Demo.account().email
      refute html =~ Demo.account().password
    end

    test "disables the demo button when the demo account is missing", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/log_in")

      assert has_element?(lv, ~s|form[action="/users/demo_log_in"] button[disabled]|)
      assert html =~ "isn&#39;t available right now"
    end

    test "the password field can be shown and hidden", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      assert has_element?(
               lv,
               ~s|#login_form button[aria-controls="user_password"][aria-pressed="false"]|
             )
    end

    test "links to the About page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")
      assert has_element?(lv, ~s|main a[href="/about"]|, "What is this? About the project")
    end

    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log_in")

      assert html =~ "Log in"
      refute html =~ "Register"
      assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/log_in")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      form =
        form(lv, "#login_form",
          user: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/users/log_in"
    end
  end

  describe "login navigation" do
    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log_in")

      {:ok, conn} =
        lv
        |> element("main a", "Forgot your password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/reset_password")

      assert conn.resp_body =~ "Forgot your password?"
    end
  end
end
