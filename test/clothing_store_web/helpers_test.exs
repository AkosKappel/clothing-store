defmodule ClothingStoreWeb.HelpersTest do
  use ExUnit.Case, async: true

  import ClothingStoreWeb.Helpers

  @now ~U[2026-10-06 12:00:00Z]

  test "relative_time/2 describes recent times and falls back to the date" do
    ago = fn seconds -> relative_time(DateTime.add(@now, -seconds), @now) end

    assert ago.(0) == "just now"
    assert ago.(59) == "just now"
    assert ago.(60) == "1 min ago"
    assert ago.(59 * 60) == "59 min ago"
    assert ago.(3600) == "1 hour ago"
    assert ago.(5 * 3600) == "5 hours ago"
    assert ago.(30 * 3600) == "yesterday"
    assert ago.(3 * 86_400) == "3 days ago"
    assert ago.(7 * 86_400) == "2026-09-29"
  end
end
