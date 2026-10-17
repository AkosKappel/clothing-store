defmodule ClothingStoreWeb.ActivityLive do
  @moduledoc "Everything that happens in the store, live: product changes and sales."
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.ActivityComponents

  alias ClothingStore.ActivityFeed

  @limit 50

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Activity
      <:subtitle>
        What visitors and simulated customers did, newest first. New events appear as they happen.
      </:subtitle>
    </.header>

    <section class="card px-5 py-2 sm:px-6">
      <.activity_list id="activity" events={@streams.events} />
      <.empty_state :if={@empty} icon="hero-bolt" title="Nothing has happened yet" class="py-10">
        Edit a product or wait a few minutes for the next simulated sale.
      </.empty_state>
    </section>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(ClothingStore.PubSub, "activity")
    events = ActivityFeed.recent(@limit)

    {:ok,
     socket
     |> assign(page_title: "Activity", empty: events == [])
     |> stream(:events, events, limit: @limit)}
  end

  @impl true
  def handle_info({:activity, event}, socket) do
    {:noreply,
     socket |> assign(:empty, false) |> stream_insert(:events, event, at: 0, limit: @limit)}
  end
end
