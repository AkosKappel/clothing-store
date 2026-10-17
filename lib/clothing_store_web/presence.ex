defmodule ClothingStoreWeb.Presence do
  @moduledoc """
  Who is here right now, without personal data: every logged-in browser session
  counts once (keyed by a hash of its session, so several tabs count once), and
  product forms track who has which product open for editing.
  """
  use Phoenix.Presence, otp_app: :clothing_store, pubsub_server: ClothingStore.PubSub

  import Phoenix.LiveView, only: [connected?: 1]

  @online "online"

  @doc "The topic every logged-in LiveView is tracked on."
  def online_topic, do: @online

  @doc "The topic of the visitors editing a product."
  def editing_topic(product_id), do: "editing:#{product_id}"

  @doc """
  on_mount hook: assigns `presence_key` (the same in every tab of a browser
  session) and tracks it on the online topic.
  """
  def on_mount(:track, _params, session, socket) do
    session_id = session["live_socket_id"] || socket.id

    key =
      :crypto.hash(:sha256, session_id) |> Base.url_encode64(padding: false) |> binary_part(0, 16)

    if connected?(socket), do: track(self(), @online, key, %{})
    {:cont, Phoenix.Component.assign(socket, :presence_key, key)}
  end

  @doc "How many browser sessions are online."
  def online_count, do: @online |> list() |> map_size()

  @doc "How many other sessions than `own_key` are on `topic`."
  def others(topic, own_key), do: topic |> list() |> Map.delete(own_key) |> map_size()
end
