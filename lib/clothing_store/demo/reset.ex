defmodule ClothingStore.Demo.Reset do
  @moduledoc """
  Puts the demo back to its seed state: every product, transaction and user
  goes, the seeds run again, and open pages are told to reload.
  """
  require Logger
  import Ecto.Query

  alias ClothingStore.Repo
  alias ClothingStore.Users.UserToken

  def run do
    Logger.info("Demo reset started")
    disconnect_live_sessions()

    Repo.query!("""
    TRUNCATE products_transactions, transactions, products, users_tokens, users
    RESTART IDENTITY CASCADE
    """)

    Code.eval_file(seeds_path())
    Phoenix.PubSub.broadcast(ClothingStore.PubSub, "products", :demo_reset)
    Logger.info("Demo reset finished")
    :ok
  end

  # Same as logging out: LiveViews of deleted sessions drop their socket.
  defp disconnect_live_sessions do
    from(t in UserToken, where: t.context == "session", select: t.token)
    |> Repo.all()
    |> Enum.each(fn token ->
      ClothingStoreWeb.Endpoint.broadcast(
        "users_sessions:#{Base.url_encode64(token)}",
        "disconnect",
        %{}
      )
    end)
  end

  defp seeds_path, do: Application.app_dir(:clothing_store, "priv/repo/seeds.exs")
end
