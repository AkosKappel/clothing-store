defmodule ClothingStore.Repo do
  use Ecto.Repo,
    otp_app: :clothing_store,
    adapter: Ecto.Adapters.Postgres
end
