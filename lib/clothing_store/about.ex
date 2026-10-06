defmodule ClothingStore.About do
  @moduledoc """
  What the About page says the demo is built with, using the versions that are
  actually running.
  """

  alias ClothingStore.Products.Product
  alias ClothingStore.Repo

  @doc "The technology stack, grouped under a few headings."
  def stack do
    [
      %{
        label: "Backend",
        items: [
          "Elixir #{System.version()} on Erlang/OTP #{:erlang.system_info(:otp_release)}",
          "Phoenix #{vsn(:phoenix)}",
          "Phoenix LiveView #{vsn(:phoenix_live_view)}",
          "Ecto #{vsn(:ecto_sql)}"
        ]
      },
      %{label: "Database", items: [with_version("PostgreSQL", database_version())]},
      %{
        label: "Frontend",
        items: [
          "HEEx templates",
          with_version("Tailwind CSS", Application.get_env(:tailwind, :version)),
          "Heroicons"
        ]
      },
      %{
        label: "Hosting",
        items: [
          "Docker (mix release)",
          "nginx",
          "Tailscale Funnel",
          "Bandit #{vsn(:bandit)} web server"
        ]
      }
    ]
  end

  @version_key {__MODULE__, :database_version}
  @retry_after_ms 60_000

  @doc """
  The PostgreSQL server's version ("18.0"), or nil when the database can't be
  asked, so the page still renders without it.

  The About page is public, so the database is asked once and the answer kept in
  :persistent_term. A failure is remembered too and asked again after a minute.
  """
  def database_version do
    case :persistent_term.get(@version_key, nil) do
      {:ok, version} ->
        version

      {:error, at} ->
        if now() - at < @retry_after_ms, do: nil, else: lookup_database_version()

      nil ->
        lookup_database_version()
    end
  end

  defp lookup_database_version do
    case query_database_version() do
      nil ->
        :persistent_term.put(@version_key, {:error, now()})
        nil

      version ->
        :persistent_term.put(@version_key, {:ok, version})
        version
    end
  end

  defp query_database_version do
    case Repo.query("SELECT current_setting('server_version')", [], timeout: 2_000) do
      {:ok, %{rows: [[version]]}} -> version |> String.split() |> List.first()
      _ -> nil
    end
  rescue
    _ -> nil
  catch
    :exit, _ -> nil
  end

  defp now, do: System.monotonic_time(:millisecond)

  @doc ~S'Where product photos may come from, by name: ["Pexels", "Unsplash"].'
  def photo_sources do
    for host <- Product.photo_hosts() do
      host |> String.split(".") |> Enum.at(-2) |> String.capitalize()
    end
  end

  defp vsn(app), do: Application.spec(app, :vsn) |> to_string()

  defp with_version(name, version) when version in [nil, ""], do: name
  defp with_version(name, version), do: "#{name} #{version}"
end
