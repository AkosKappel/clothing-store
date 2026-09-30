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

  @doc """
  True when the database has neither products nor users, i.e. it has never been seeded.
  Visitors can delete every product, but the demo user stays, so users count too.
  """
  def fresh_database?(repo) do
    not (repo.exists?(ClothingStore.Products.Product) or
           repo.exists?(ClothingStore.Users.User))
  end

  @doc """
  Seeds a fresh database (first start); does nothing when any product or user exists.
  The seeds run in one transaction, so a failure leaves the database empty.
  """
  def seed_if_empty(seeds_path \\ Application.app_dir(@app, "priv/repo/seeds.exs")) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(ClothingStore.Repo, fn repo ->
        if fresh_database?(repo) do
          # The seeds broadcast on PubSub and use time zones; neither app runs in `eval`.
          {:ok, _} = Application.ensure_all_started([:phoenix_pubsub, :tzdata])

          {:ok, _} =
            Supervisor.start_link([{Phoenix.PubSub, name: ClothingStore.PubSub}],
              strategy: :one_for_one
            )

          # One transaction: a failing seed rolls back and raises, so the next start retries.
          {:ok, _} =
            repo.transaction(fn -> Code.eval_file(seeds_path) end, timeout: :timer.minutes(1))
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
