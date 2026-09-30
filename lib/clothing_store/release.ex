defmodule ClothingStore.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :clothing_store

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc "Seeds a fresh database (first start); does nothing when products exist."
  def seed_if_empty do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(ClothingStore.Repo, fn repo ->
        unless repo.exists?(ClothingStore.Products.Product) do
          # The seeds broadcast on PubSub and use time zones; neither app runs in `eval`.
          {:ok, _} = Application.ensure_all_started([:phoenix_pubsub, :tzdata])

          {:ok, _} =
            Supervisor.start_link([{Phoenix.PubSub, name: ClothingStore.PubSub}],
              strategy: :one_for_one
            )

          Code.eval_file(Application.app_dir(@app, "priv/repo/seeds.exs"))
        end
      end)

    :ok
  end

  @doc "Manual reset from the shell: bin/clothing_store rpc 'ClothingStore.Release.reset_demo()'"
  def reset_demo, do: ClothingStore.Demo.Reset.run()

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
