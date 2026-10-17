defmodule ClothingStoreWeb.PresenceLiveTest do
  # not async: presence topics are shared
  use ClothingStoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ClothingStore.ProductsFixtures

  defp logged_in_conn, do: register_and_log_in_user(%{conn: build_conn()}).conn

  # presence changes arrive as broadcasts, a moment after the tracking call
  defp eventually(fun, tries \\ 50) do
    fun.()
  rescue
    error in ExUnit.AssertionError ->
      if tries == 0, do: reraise(error, __STACKTRACE__)
      Process.sleep(20)
      eventually(fun, tries - 1)
  end

  defp online(lv), do: Regex.run(~r/\d+ visitors? online/, render(lv))

  test "the dashboard counts sessions, not tabs" do
    alias ClothingStoreWeb.Presence

    conn = logged_in_conn()
    {:ok, lv, _html} = live(conn, ~p"/")
    # LiveViews of earlier tests may still be leaving the topic
    eventually(fn -> assert online(lv) == [online_text(Presence.online_count())] end)
    before = Presence.online_count()

    {:ok, _second_tab, _html} = live(conn, ~p"/")
    {:ok, _other, _html} = live(logged_in_conn(), ~p"/")
    eventually(fn -> assert online(lv) == [online_text(before + 1)] end)
  end

  defp online_text(1), do: "1 visitor online"
  defp online_text(n), do: "#{n} visitors online"

  test "the edit form warns when someone else edits the same product" do
    product = product_fixture()
    {:ok, mine, html} = live(logged_in_conn(), ~p"/products/#{product}/edit")
    refute html =~ "Another visitor is editing"

    {:ok, theirs, _html} = live(logged_in_conn(), ~p"/products/#{product}/edit")
    eventually(fn -> assert render(theirs) =~ "Another visitor is editing this product" end)
    eventually(fn -> assert render(mine) =~ "Another visitor is editing this product" end)

    GenServer.stop(theirs.pid)
    eventually(fn -> refute render(mine) =~ "Another visitor is editing" end)
  end
end
