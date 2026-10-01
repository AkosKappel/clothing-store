defmodule ClothingStoreWeb.UserLoginLive do
  use ClothingStoreWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm mt-16">
      <.header class="text-center">
        Log in to your account
        <%!-- <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle> --%>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <p class="rounded-md bg-amber-50 border border-amber-200 p-3 text-sm text-amber-900">
          <strong>Demo account</strong>: just press <em>Log in</em>. Feel free to add, edit and delete
          products; the data resets every night.
        </p>
        <.input field={@form[:email]} type="email" label="Email" value={@demo.email} required />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          value={@demo.password}
          required
        />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <p class="mt-8 text-center text-sm">
        <.link href={~p"/about"} class="font-semibold text-gray-800 underline underline-offset-4">
          What is this? About the project
        </.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, demo: ClothingStore.Demo.account()),
     temporary_assigns: [form: form]}
  end
end
