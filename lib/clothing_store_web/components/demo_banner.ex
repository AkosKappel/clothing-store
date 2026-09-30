defmodule ClothingStoreWeb.DemoBanner do
  @moduledoc "Site-wide notice that this is a public demo with nightly data resets."
  use Phoenix.Component

  def demo_banner(assigns) do
    assigns = assign(assigns, :reset, ClothingStore.Demo.reset_settings())

    ~H"""
    <div class="bg-amber-300 text-amber-950 text-center text-sm py-1.5 px-4" role="note">
      Demo dashboard: feel free to edit anything. All data resets every night at {Calendar.strftime(
        @reset.time,
        "%H:%M"
      )} ({@reset.timezone} time).
    </div>
    """
  end
end
