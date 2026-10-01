defmodule ClothingStore.DemoLinksTest do
  # changes the :demo application env, so it can't run next to other tests
  use ExUnit.Case, async: false

  alias ClothingStore.Demo

  setup do
    original = Application.fetch_env!(:clothing_store, :demo)
    on_exit(fn -> Application.put_env(:clothing_store, :demo, original) end)
    %{original: original}
  end

  defp put_links(original, links) do
    Application.put_env(:clothing_store, :demo, Keyword.put(original, :links, links))
  end

  test "links/0 returns the configured links in a fixed order", %{original: original} do
    put_links(original,
      repository: "https://example.com/repo",
      portfolio: "https://example.com",
      linkedin: "https://linkedin.example.com/me",
      github: "https://github.example.com/me"
    )

    assert Demo.links() == [
             github: "https://github.example.com/me",
             linkedin: "https://linkedin.example.com/me",
             portfolio: "https://example.com",
             repository: "https://example.com/repo"
           ]
  end

  test "links/0 leaves out empty and missing links", %{original: original} do
    put_links(original, github: "https://github.example.com/me", linkedin: "", portfolio: nil)

    assert Demo.links() == [github: "https://github.example.com/me"]
  end

  # read from the config files rather than the running app, whose links DEMO_*_URL
  # variables in the shell may have overridden
  test "the default config has GitHub, LinkedIn and the repository but no portfolio", %{
    original: original
  } do
    defaults = Config.Reader.read!("config/config.exs", env: :test)[:clothing_store][:demo]
    put_links(original, defaults[:links])

    assert Keyword.keys(Demo.links()) == [:github, :linkedin, :repository]
    assert defaults[:author] == "Ákos Kappel"
  end
end
