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
          "flex items-center gap-2 rounded-md px-3 py-2 text-sm font-semibold whitespace-nowrap transition-colors",
          "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white",
          if(@active,
            do: "bg-gray-900 text-red-400",
            else: "text-gray-200 hover:bg-gray-700 hover:text-white"
          )
        ]}
      >
        <.icon name={@icon} class="size-5 opacity-80 lg:max-xl:hidden" />
        {render_slot(@inner_block)}
      </.link>
    </li>
    """
  end

  @doc """
  Explains the demo on the first visit, decided server-side from the
  `welcome_seen` cookie so the page never flashes it. `app.js` opens it and sets
  the cookie when it closes; the header and footer reopen it. It lives in the
  root layout, outside the LiveView, so live updates never touch it.
  """
  attr :open_on_load, :boolean, required: true
  attr :logged_in, :boolean, required: true

  def welcome_dialog(assigns) do
    assigns = assign(assigns, :reset, ClothingStore.Demo.reset_settings())

    ~H"""
    <dialog
      id="welcome"
      data-open-on-load={@open_on_load}
      aria-labelledby="welcome-title"
      closedby="any"
      class={[
        "m-auto w-[calc(100%-2rem)] max-w-lg rounded-xl bg-white p-0 text-left shadow-2xl backdrop:bg-gray-900/60",
        "motion-safe:transition-[opacity,scale] motion-safe:duration-200 motion-safe:starting:open:scale-95 motion-safe:starting:open:opacity-0"
      ]}
    >
      <div class="flex items-center justify-between gap-4 bg-gray-800 px-6 py-4">
        <div class="flex items-center gap-2">
          <img src={~p"/images/logo.svg"} width="32" height="32" alt="" />
          <span class="font-display text-lg font-bold text-red-400 italic">Modern Fashion Store</span>
        </div>
        <form method="dialog">
          <button
            class="rounded-md p-1 text-gray-300 hover:bg-gray-700 hover:text-white focus-visible:outline-2 focus-visible:outline-white"
            aria-label="Close"
            title="Close"
          >
            <.icon name="hero-x-mark" />
          </button>
        </form>
      </div>

      <div class="px-6 py-6">
        <h2 id="welcome-title" class="font-display text-2xl font-bold text-gray-900">
          Welcome to the demo
        </h2>
        <p class="mt-2 text-gray-600">
          This is a manager dashboard for a clothing store, built as a portfolio project with
          Elixir and Phoenix LiveView. Everything here is sample data, so go ahead and try:
        </p>
        <ul class="mt-4 space-y-2.5 text-sm text-gray-700">
          <li
            :for={
              {icon, text} <- [
                {"hero-pencil-square", "Add, edit and delete products"},
                {"hero-funnel", "Filter the inventory by category, price, stock and tags"},
                {"hero-bolt", "Open the dashboard in a second tab and watch changes appear live"},
                {"hero-chart-bar", "Check the transactions and the bestsellers"}
              ]
            }
            class="flex gap-3"
          >
            <.icon name={icon} class="size-5 shrink-0 text-red-600" />
            {text}
          </li>
        </ul>
        <p class="mt-5 flex gap-2 rounded-md bg-amber-50 p-3 text-sm text-amber-900 ring-1 ring-amber-600/20">
          <.icon name="hero-arrow-path-mini" class="size-5 shrink-0 text-amber-600" />
          All data resets every night at {Calendar.strftime(@reset.time, "%H:%M")} ({@reset.timezone}).
        </p>
      </div>

      <div class="flex flex-wrap justify-end gap-3 border-t border-gray-100 bg-gray-50 px-6 py-4">
        <.button href={~p"/about"} variant="secondary">About the project</.button>
        <.form :if={!@logged_in} for={%{}} action={~p"/users/demo_log_in"} method="post">
          <.button type="submit" icon="hero-play">Try the demo</.button>
        </.form>
        <form :if={@logged_in} method="dialog">
          <.button icon="hero-arrow-right">Start exploring</.button>
        </form>
      </div>
    </dialog>
    """
  end

  @doc "Site footer: what the demo is, links (empty `DEMO_*` links are left out), stack and author."
  def site_footer(assigns) do
    assigns =
      assign(assigns,
        links: ClothingStore.Demo.links(),
        author: ClothingStore.Demo.author(),
        reset: ClothingStore.Demo.reset_settings()
      )

    ~H"""
    <footer class="mt-16 bg-gray-800 text-sm text-gray-300">
      <div class="mx-auto grid max-w-7xl gap-10 px-4 py-12 sm:px-6 md:grid-cols-3 lg:px-8">
        <div>
          <a href="/" class="flex items-center gap-2">
            <img src={~p"/images/logo.svg"} width="32" height="32" alt="" />
            <span class="font-display text-lg font-bold text-red-400 italic">
              Modern Fashion Store
            </span>
          </a>
          <p class="mt-4 max-w-xs leading-relaxed">
            A manager dashboard for a clothing store, built as a portfolio demo. Everything is
            sample data and resets every night at {Calendar.strftime(@reset.time, "%H:%M")} ({@reset.timezone}).
          </p>
        </div>

        <nav aria-labelledby="footer-links">
          <h2 id="footer-links" class="font-semibold text-white">Project</h2>
          <ul class="mt-4 space-y-2">
            <li>
              <.link href={~p"/about"} class="hover:text-white hover:underline">
                About this project
              </.link>
            </li>
            <li>
              <button
                type="button"
                commandfor="welcome"
                command="show-modal"
                class="hover:text-white hover:underline"
              >
                What can I try here?
              </button>
            </li>
            <li :for={{key, url} <- @links}>
              <a
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 hover:text-white hover:underline"
              >
                {ClothingStoreWeb.PageHTML.link_label(key)}
                <.icon name="hero-arrow-top-right-on-square-mini" class="size-4 opacity-70" />
              </a>
            </li>
          </ul>
        </nav>

        <div>
          <h2 class="font-semibold text-white">Built with</h2>
          <ul class="mt-4 flex flex-wrap gap-2">
            <li
              :for={tech <- ["Elixir", "Phoenix LiveView", "PostgreSQL", "Tailwind CSS", "Docker"]}
              class="rounded-full px-3 py-1 whitespace-nowrap text-xs font-medium text-gray-200 ring-1 ring-gray-600 ring-inset"
            >
              {tech}
            </li>
          </ul>
        </div>
      </div>
      <div class="border-t border-gray-700">
        <p class="mx-auto max-w-7xl px-4 py-5 text-gray-400 sm:px-6 lg:px-8">
          &copy; {Date.utc_today().year} {@author}. Product photos from Pexels.
        </p>
      </div>
    </footer>
    """
  end

  defp active?("/", current_path), do: current_path == "/"
  defp active?(href, current_path), do: String.starts_with?(current_path, href)
end
