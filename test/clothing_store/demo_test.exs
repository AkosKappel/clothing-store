defmodule ClothingStore.DemoTest do
  # sets the :demo application env, so it can't run next to other tests
  use ExUnit.Case, async: false

  alias ClothingStore.Demo
  alias ClothingStore.Users.User

  # explicit settings, so DEMO_* / ADMIN_* variables in the shell don't matter
  setup do
    original = Application.fetch_env!(:clothing_store, :demo)
    on_exit(fn -> Application.put_env(:clothing_store, :demo, original) end)

    Application.put_env(:clothing_store, :demo,
      account: [email: "demo@example.com", password: "secret123456"],
      reset: [enabled: true, time: "04:30", timezone: "Europe/Bratislava"],
      author: "Test Author",
      links: [github: "https://github.example.com/me"]
    )
  end

  test "account/0 reads the configured demo account" do
    assert Demo.account() == %{email: "demo@example.com", password: "secret123456"}
  end

  test "locked?/1 is true only for the demo account" do
    assert Demo.locked?(%User{email: Demo.account().email})
    refute Demo.locked?(%User{email: "someone@example.com"})
    refute Demo.locked?(nil)
  end

  test "reset_settings/0 has a Time and a time zone" do
    assert Demo.reset_settings() == %{
             enabled: true,
             time: ~T[04:30:00],
             timezone: "Europe/Bratislava"
           }
  end

  test "author/0 is the configured author's name" do
    assert Demo.author() == "Test Author"
  end
end
