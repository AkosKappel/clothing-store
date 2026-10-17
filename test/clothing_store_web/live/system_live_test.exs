defmodule ClothingStoreWeb.SystemLiveTest do
  use ClothingStoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ClothingStoreWeb.SystemLive

  test "is public and updates on every tick", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/system")

    assert html =~ "Processes"
    assert html =~ System.version()

    send(view.pid, :tick)
    assert render(view) =~ "Uptime"
  end

  test "stats/1 counts down to the next reset" do
    stats = SystemLive.stats()
    assert stats.processes > 0
    assert stats.memory_mb > 0
    assert stats.next_reset_s == false or stats.next_reset_s in 1..86_400
  end

  test "duration/1 picks the two largest units" do
    assert SystemLive.duration(7) == "7s"
    assert SystemLive.duration(427) == "7m 07s"
    assert SystemLive.duration(14_700) == "4h 05m"
    assert SystemLive.duration(273_600) == "3d 4h"
  end
end
