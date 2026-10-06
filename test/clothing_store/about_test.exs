defmodule ClothingStore.AboutTest do
  # database_version/0 caches in :persistent_term, which is global
  use ClothingStore.DataCase, async: false

  alias ClothingStore.About
  alias Ecto.Adapters.SQL.Sandbox

  @version_key {ClothingStore.About, :database_version}

  setup do
    :persistent_term.erase(@version_key)
    on_exit(fn -> :persistent_term.erase(@version_key) end)
  end

  defp now, do: System.monotonic_time(:millisecond)

  # A process outside the SQL sandbox can't use the database, as if it were down.
  # Sync tests share their connection with every process, so switch that off first.
  defp without_database(fun) do
    Sandbox.mode(ClothingStore.Repo, :manual)
    parent = self()
    spawn(fn -> send(parent, {:result, fun.()}) end)
    assert_receive {:result, result}, 5_000
    result
  end

  test "stack/0 groups non-empty entries under each heading" do
    stack = About.stack()

    assert Enum.map(stack, & &1.label) == ["Backend", "Database", "Frontend", "Hosting"]

    for %{items: items} <- stack do
      assert items != []
      assert Enum.all?(items, &(is_binary(&1) and &1 != ""))
    end
  end

  test "stack/0 reports the running versions" do
    items = Enum.flat_map(About.stack(), & &1.items)

    assert "Elixir #{System.version()} on Erlang/OTP #{:erlang.system_info(:otp_release)}" in items
    assert "Phoenix #{Application.spec(:phoenix, :vsn)}" in items
    assert "Phoenix LiveView #{Application.spec(:phoenix_live_view, :vsn)}" in items
    assert "Ecto #{Application.spec(:ecto_sql, :vsn)}" in items
    assert Enum.any?(items, &String.starts_with?(&1, "PostgreSQL"))
    assert Enum.any?(items, &String.starts_with?(&1, "Tailwind CSS"))
    assert "Bandit #{Application.spec(:bandit, :vsn)} web server" in items
  end

  describe "database_version/0" do
    test "reads the server's major.minor version and caches it" do
      version = About.database_version()
      assert version =~ ~r/^\d+(\.\d+)?$/
      assert :persistent_term.get(@version_key) == {:ok, version}
    end

    test "answers from the cache without asking the database" do
      :persistent_term.put(@version_key, {:ok, "99.9"})
      assert without_database(&About.database_version/0) == "99.9"
    end

    test "is nil when the database can't be asked, and remembers the failure" do
      assert without_database(&About.database_version/0) == nil
      assert {:error, _at} = :persistent_term.get(@version_key)
    end

    test "doesn't ask again within a minute of a failure" do
      :persistent_term.put(@version_key, {:error, now()})
      assert About.database_version() == nil
    end

    test "asks again a minute after a failure" do
      :persistent_term.put(@version_key, {:error, now() - 61_000})
      assert About.database_version() =~ ~r/^\d+(\.\d+)?$/
      assert {:ok, _} = :persistent_term.get(@version_key)
    end
  end

  test "photo_sources/0 names the allowed photo hosts" do
    assert About.photo_sources() == ["Pexels", "Unsplash"]
  end
end
