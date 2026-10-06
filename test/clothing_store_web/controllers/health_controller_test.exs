defmodule ClothingStoreWeb.HealthControllerTest do
  # not async: the 503 test switches the SQL sandbox to manual mode for the whole repo
  use ClothingStoreWeb.ConnCase, async: false

  alias ClothingStoreWeb.HealthController
  alias Ecto.Adapters.SQL.Sandbox

  test "GET /health answers 200 while the database is reachable", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "GET /health needs no session or login", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert get_resp_header(conn, "set-cookie") == []
  end

  test "answers 503 when the database can't be reached", %{conn: conn} do
    # a process outside the sandbox can't use the database, as if it were down
    Sandbox.mode(ClothingStore.Repo, :manual)
    parent = self()
    spawn(fn -> send(parent, {:conn, HealthController.show(conn, %{})}) end)

    assert_receive {:conn, conn}, 5_000
    assert json_response(conn, 503) == %{"status" => "error"}
  end
end
