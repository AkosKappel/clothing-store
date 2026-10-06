defmodule ClothingStoreWeb.UserLoginLive do
  use ClothingStoreWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md pt-4 sm:pt-8">
      <.header class="justify-center text-center">
        Log in
        <:subtitle>Manage the products, stock and sales of the store.</:subtitle>
      </.header>

      <div class="card p-6 sm:p-8">
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
            required
          />

          <:actions>
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
            <.link
              href={~p"/users/reset_password"}
              class="text-sm font-semibold text-gray-800 underline decoration-red-600 underline-offset-4 hover:text-red-700"
            >
              Forgot your password?
            </.link>
          </:actions>
          <:actions>
            <.button
              type="submit"
              icon="hero-arrow-right-end-on-rectangle"
              class="w-full py-2.5"
            >
              Log in
            </.button>
          </:actions>
        </.simple_form>

        <div class="my-6 flex items-center gap-3 text-xs font-medium tracking-wide text-gray-500 uppercase">
          <span class="h-px flex-1 bg-gray-200"></span>
          or just look around <span class="h-px flex-1 bg-gray-200"></span>
        </div>

        <section aria-labelledby="demo-title">
          <h2 id="demo-title" class="sr-only">Demo</h2>
          <p class="text-sm text-gray-600">
            Try the dashboard with the shared demo account: add, edit and delete anything.
            The data resets every night.
          </p>
          <.form for={%{}} action={~p"/users/demo_log_in"} method="post" class="mt-4">
            <.button
              type="submit"
              variant="secondary"
              icon="hero-play"
              class="w-full py-2.5"
              disabled={!@demo_available}
            >
              Try the demo
            </.button>
          </.form>
          <p :if={!@demo_available} class="mt-2 text-sm text-gray-500">
            The demo account isn't available right now.
          </p>
        </section>
      </div>

      <p class="mt-6 text-center text-sm">
        <.link
          href={~p"/about"}
          class="font-semibold text-gray-800 underline decoration-red-600 underline-offset-4 hover:text-red-700"
        >
          What is this? About the project
        </.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    demo_available =
      ClothingStore.Users.get_user_by_email(ClothingStore.Demo.account().email) != nil

    {:ok, assign(socket, form: form, demo_available: demo_available, page_title: "Log in"),
     temporary_assigns: [form: form]}
  end
end
