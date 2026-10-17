defmodule ClothingStoreWeb.HelpersTest do
  use ExUnit.Case, async: true

  import ClothingStoreWeb.Helpers

  test "password_score/1 rewards length first, then variety" do
    assert password_score("") == 0
    assert password_score(nil) == 0
    assert password_score("abc") == 1
    assert password_score("abcdefghijkl") == 1
    assert password_score("abcdefghijk1") == 2
    assert password_score("Abcdefghijk1") == 3
    assert password_score("Abcdefghijk1-longer") == 4
  end
end
