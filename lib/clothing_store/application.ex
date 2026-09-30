defmodule ClothingStore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ClothingStoreWeb.Telemetry,
        ClothingStore.Repo,
        {DNSCluster, query: Application.get_env(:clothing_store, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: ClothingStore.PubSub},
        {Finch, name: ClothingStore.Finch}
      ] ++ demo_children() ++ [ClothingStoreWeb.Endpoint]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClothingStore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp demo_children do
    if ClothingStore.Demo.reset_settings().enabled, do: [ClothingStore.Demo.Scheduler], else: []
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClothingStoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
