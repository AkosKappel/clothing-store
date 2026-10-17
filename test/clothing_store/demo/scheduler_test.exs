defmodule ClothingStore.Demo.SchedulerTest do
  use ExUnit.Case, async: true
  alias ClothingStore.Demo.Scheduler

  @tz "Europe/Bratislava"

  test "later the same day" do
    assert Scheduler.next_run(~U[2026-09-30 00:30:00Z], ~T[03:00:00], @tz) ==
             ~U[2026-09-30 01:00:00Z]
  end

  test "tomorrow when today's time has passed" do
    assert Scheduler.next_run(~U[2026-09-30 01:00:00Z], ~T[03:00:00], @tz) ==
             ~U[2026-10-01 01:00:00Z]
  end

  test "winter time" do
    assert Scheduler.next_run(~U[2026-12-01 12:00:00Z], ~T[03:00:00], @tz) ==
             ~U[2026-12-02 02:00:00Z]
  end

  test "a time that doesn't exist on the spring-forward day runs just after the gap" do
    # 2027-03-28 02:00-03:00 doesn't exist in Bratislava
    assert Scheduler.next_run(~U[2027-03-27 12:00:00Z], ~T[02:30:00], @tz) ==
             ~U[2027-03-28 01:00:00Z]
  end

  test "a time that happens twice on the fall-back day runs at the first one" do
    # 2026-10-25 02:00-03:00 happens twice in Bratislava (CEST, then CET)
    assert Scheduler.next_run(~U[2026-10-24 12:00:00Z], ~T[02:30:00], @tz) ==
             ~U[2026-10-25 00:30:00Z]
  end
end
