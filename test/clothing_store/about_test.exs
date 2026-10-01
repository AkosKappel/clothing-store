defmodule ClothingStore.AboutTest do
  use ClothingStore.DataCase, async: true

  alias ClothingStore.About

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

  test "database_version/0 reads the server's major.minor version" do
    assert About.database_version() =~ ~r/^\d+(\.\d+)?$/
  end

  test "photo_sources/0 names the allowed photo hosts" do
    assert About.photo_sources() == ["Pexels", "Unsplash"]
  end
end
