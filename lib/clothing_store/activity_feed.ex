defmodule ClothingStore.ActivityFeed do
  @moduledoc """
  What happened in the store, newest first: products added, changed, deleted and
  restocked, and sales. Every event is stored (the nightly reset clears them) and
  broadcast on the "activity" topic as `{:activity, event}`.
  """
  import Ecto.Query

  alias ClothingStore.ActivityFeed.Event
  alias ClothingStore.Repo

  # fields worth showing in the feed when they change
  @tracked ~w(title category price stock tags description photo discount_percent discount_starts_on discount_ends_on)a

  @doc "The latest `limit` events, newest first."
  def recent(limit \\ 50) do
    Event
    |> order_by(desc: :inserted_at, desc: :id)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "Records a product event; for updates only the changes in `@tracked` fields count."
  def product_event(kind, product, changes \\ %{})

  def product_event("updated", _product, changes) when map_size(changes) == 0, do: :ok

  def product_event(kind, product, changes) do
    record(%Event{
      kind: kind,
      # a deleted product's row is gone, so its events only keep the title
      product_id: if(kind == "deleted", do: nil, else: product.id),
      product_title: product.title,
      data: %{"changes" => changes}
    })
  end

  @doc "The `{field => [old, new]}` changes between two versions of a product."
  def changes(old, new) do
    for field <- @tracked,
        not same?(Map.get(old, field), Map.get(new, field)),
        into: %{},
        do: {to_string(field), [Map.get(old, field), Map.get(new, field)]}
  end

  @doc "Records a sale of `[{product, quantity}]`."
  def sale_event(sold, total) do
    record(%Event{
      kind: "sale",
      data: %{
        "items" => Enum.map(sold, fn {product, quantity} -> [product.title, quantity] end),
        "total" => total
      }
    })
  end

  defp same?(%Decimal{} = old, %Decimal{} = new), do: Decimal.equal?(old, new)
  defp same?(old, new), do: old == new

  defp record(event) do
    # stored as JSON, so read back the way a fresh load would see it
    event = event |> Repo.insert!() |> then(&Repo.get!(Event, &1.id))
    Phoenix.PubSub.broadcast(ClothingStore.PubSub, "activity", {:activity, event})
    :ok
  end
end
