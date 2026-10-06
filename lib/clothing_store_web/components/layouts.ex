defmodule ClothingStoreWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ClothingStoreWeb, :controller` and
  `use ClothingStoreWeb, :live_view`.
  """
  use ClothingStoreWeb, :html

  embed_templates "layouts/*"

  @doc "A main navigation link, highlighted when `current_path` is its page or below it."
  attr :href, :string, required: true
  attr :current_path, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  def nav_link(assigns) do
    assigns = assign(assigns, :active, active?(assigns.href, assigns.current_path))

    ~H"""
    <li>
      <.link
        href={@href}
        aria-current={@active && "page"}
        class={[
          "flex items-center gap-2 rounded-md px-3 py-2 text-sm font-semibold transition-colors",
          "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white",
          if(@active,
            do: "bg-gray-900 text-red-400",
            else: "text-gray-200 hover:bg-gray-700 hover:text-white"
          )
        ]}
      >
        <.icon name={@icon} class="size-5 opacity-80" />
        {render_slot(@inner_block)}
      </.link>
    </li>
    """
  end

  defp active?("/", current_path), do: current_path == "/"
  defp active?(href, current_path), do: String.starts_with?(current_path, href)
end
