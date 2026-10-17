defmodule ClothingStore.ActivityFeed.Event do
  @moduledoc """
  Something that happened in the store. `kind` is one of `#{inspect(~w(created updated deleted restocked sale))}`;
  `data` holds the details: `"changes"` (`%{field => [old, new]}`) for updates and
  restocks, `"items"` (`[[title, quantity]]`) and `"total"` for sales.
  """
  use Ecto.Schema

  schema "activity_events" do
    field :kind, :string
    field :product_id, :id
    field :product_title, :string
    field :data, :map, default: %{}
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
