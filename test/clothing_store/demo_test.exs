defmodule ClothingStore.DemoTest do
  use ExUnit.Case, async: true

  alias ClothingStore.Demo
  alias ClothingStore.Users.User

  test "account/0 reads the configured demo account" do
    assert %{email: email, password: password} = Demo.account()
    assert is_binary(email) and is_binary(password)
  end

  test "locked?/1 is true only for the demo account" do
    assert Demo.locked?(%User{email: Demo.account().email})
    refute Demo.locked?(%User{email: "someone@example.com"})
    refute Demo.locked?(nil)
  end

  test "reset_settings/0 has a Time and a time zone" do
    assert %{enabled: enabled, time: %Time{}, timezone: tz} = Demo.reset_settings()
    assert is_boolean(enabled) and is_binary(tz)
  end
end
