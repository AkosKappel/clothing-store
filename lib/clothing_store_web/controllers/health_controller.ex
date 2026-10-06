defmodule ClothingStoreWeb.HealthController do
  @moduledoc """
  `GET /health` for the Docker health check and uptime checks: 200 when the app
  can query the database, 503 otherwise. It reveals nothing else.
  """
  use ClothingStoreWeb, :controller

  def show(conn, _params) do
    if database_up?() do
      json(conn, %{status: "ok"})
    else
      conn |> put_status(:service_unavailable) |> json(%{status: "error"})
    end
  end

  # a pool that can't connect returns an error, raises or exits, depending on where it fails
  defp database_up? do
    match?({:ok, _}, ClothingStore.Repo.query("SELECT 1", [], timeout: 2_000))
  rescue
    _ -> false
  catch
    :exit, _ -> false
  end
end
