defmodule ClothingStoreWeb.ChartComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import ClothingStoreWeb.ChartComponents

  test "nice_scale/2 picks round steps that cover the maximum" do
    assert nice_scale(4_870, 4) == {2000, 3}
    assert nice_scale(100, 4) == {25, 4}
    assert nice_scale(9, 4) == {2.5, 4}
    assert nice_scale(0, 4) == {1, 4}
  end

  test "bar_chart/1 sizes bars against the axis and gives each a tooltip" do
    html =
      render_component(&bar_chart/1,
        id: "chart",
        title: "Revenue",
        format: &"#{&1} €",
        bars: [
          %{label: "Sep", value: 50, tooltip: "September: 50 €"},
          %{label: "Oct", value: 100, tooltip: "October: 100 €"}
        ]
      )

    assert html =~ "height: 50.0%"
    assert html =~ "height: 100.0%"
    assert html =~ ~s(aria-label="October: 100 €")
  end

  test "donut_chart/1 lists each segment with its share" do
    html =
      render_component(&donut_chart/1,
        id: "donut",
        title: "Categories",
        total_text: "400 €",
        segments: [
          %{label: "Shoes", value: 300, color: "#008300", text: "300 €"},
          %{label: "Shirts", value: 100, color: "#2a78d6", text: "100 €"}
        ]
      )

    assert html =~ "Shoes"
    assert html =~ "75 %"
    assert html =~ "25 %"
  end
end
