defmodule ClothingStoreWeb.UserLoginLive do
  use ClothingStoreWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md pt-4 sm:pt-8">
      <.header class="justify-center text-center">
        Log in to your account
        <:subtitle>Manage the products, stock and sales of the store.</:subtitle>
      </.header>

      <div class="card p-6 sm:p-8">
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
          <p class="flex gap-3 rounded-md bg-amber-50 p-4 text-sm text-amber-900 ring-1 ring-amber-600/20">
            <.icon name="hero-information-circle-mini" class="size-5 shrink-0 text-amber-600" />
            <span>
              <strong>Demo account</strong>: just press <em>Log in</em>. Feel free to add, edit and
              delete products; the data resets every night.
            </span>
          </p>
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            value={@demo.email}
            autocomplete="username"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            value={@demo.password}
            autocomplete="current-password"
            required
          />

          <:actions>
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
            <.link
              href={~p"/users/reset_password"}
              class="font-semibold text-gray-800 underline decoration-red-600 underline-offset-4 hover:text-red-700"
            >
              Forgot your password?
            </.link>
          </:actions>
          <:actions>
            <.button type="submit" icon="hero-arrow-right-end-on-rectangle" class="w-full">
              Log in
            </.button>
          </:actions>
        </.simple_form>
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

    {:ok, assign(socket, form: form, demo: ClothingStore.Demo.account(), page_title: "Log in"),
     temporary_assigns: [form: form]}
  end
end
