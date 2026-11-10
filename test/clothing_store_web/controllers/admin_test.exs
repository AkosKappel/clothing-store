defmodule ClothingStoreWeb.AdminTest do
  use ClothingStoreWeb.ConnCase, async: true

  import ClothingStore.UsersFixtures

  defp admin_fixture do
    user_fixture() |> Ecto.Changeset.change(role: "admin") |> ClothingStore.Repo.update!()
  end

  test "the dashboard does not exist for the demo account", %{conn: conn} do
    conn = conn |> log_in_user(user_fixture()) |> get(~p"/admin/dashboard/home")
    assert html_response(conn, 404)
  end

  test "signed-out visitors are sent to log in", %{conn: conn} do
    conn = get(conn, ~p"/admin/dashboard/home")
    assert redirected_to(conn) == ~p"/users/log_in"
  end

  test "an admin sees the dashboard, its scripts allowed by a nonce", %{conn: conn} do
    conn = conn |> log_in_user(admin_fixture()) |> get(~p"/admin/dashboard/home")
    assert html_response(conn, 200) =~ "Dashboard"
    [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ ~r/script-src 'self' 'nonce-[^']+'/
  end

  test "only an admin gets the link in the menu", %{conn: conn} do
    refute conn |> log_in_user(user_fixture()) |> get(~p"/") |> html_response(200) =~
             "/admin/dashboard"

    assert build_conn() |> log_in_user(admin_fixture()) |> get(~p"/") |> html_response(200) =~
             "/admin/dashboard"
  end
end
