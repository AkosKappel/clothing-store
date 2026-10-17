defmodule ClothingStore.Demo.Activity do
  @moduledoc """
  Simulated customers, so the demo moves while someone watches: every few
  minutes one or two in-stock products sell, and now and then a sold-out or
  low product is restocked. Bounded per day; the nightly reset clears it all.
  Started only when DEMO_ACTIVITY_ENABLED is true.
  """
  use GenServer
  require Logger

  import Ecto.Query

  alias ClothingStore.{Products, Repo, Transactions}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    settings = settings()
    schedule(settings)
    {:ok, settings}
  end

  @impl true
  def handle_info(:tick, settings) do
    try do
      simulate(settings.daily_limit)
    rescue
      e -> Logger.error("Simulated sale failed: " <> Exception.message(e))
    end

    schedule(settings)
    {:noreply, settings}
  end

  @doc """
  One round of activity: a sale of one or two random in-stock products (unless
  `daily_limit` sales happened today), and with a one-in-five chance a restock of
  the emptiest product. Returns what happened, for the tests.
  """
  def simulate(daily_limit) do
    sale =
      if Transactions.count_today() < daily_limit do
        case random_products(Enum.random(1..2)) do
          [] ->
            nil

          products ->
            Transactions.record_sale(Enum.map(products, &{&1, Enum.random(1..min(2, &1.stock))}))
        end
      end

    restock =
      if :rand.uniform() < 0.2 do
        Products.active()
        |> where([p], p.stock <= ^Products.low_stock())
        |> order_by([p], asc: p.stock, asc: p.id)
        |> limit(1)
        |> Repo.one()
        |> then(&(&1 && Products.restock_product(&1)))
      end

    %{sale: sale, restock: restock}
  end

  defp random_products(count) do
    Products.active()
    |> where([p], p.stock > 0)
    |> order_by(fragment("random()"))
    |> limit(^count)
    |> Repo.all()
  end

  # a little jitter, so sales don't tick like a clock
  defp schedule(%{interval_ms: interval}) do
    Process.send_after(self(), :tick, round(interval * (0.7 + :rand.uniform() * 0.6)))
  end

  defp settings do
    config = Application.fetch_env!(:clothing_store, :demo)[:activity] || []

    %{
      interval_ms: :timer.minutes(Keyword.get(config, :interval_minutes, 4)),
      daily_limit: Keyword.get(config, :daily_limit, 300)
    }
  end

  @doc "Whether the simulation is switched on."
  def enabled?,
    do: (Application.fetch_env!(:clothing_store, :demo)[:activity] || [])[:enabled] == true
end
