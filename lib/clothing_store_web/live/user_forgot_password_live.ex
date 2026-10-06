defmodule ClothingStoreWeb.UserForgotPasswordLive do
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Users

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md pt-4 sm:pt-8">
      <.header class="justify-center text-center">
        Forgot your password?
        <:subtitle>We'll send a password reset link to your inbox.</:subtitle>
      </.header>

      <div class="card p-6 sm:p-8">
        <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
          />
          <:actions>
            <.button phx-disable-with="Sending..." icon="hero-envelope" class="w-full">
              Send password reset instructions
            </.button>
          </:actions>
        </.simple_form>
      </div>

      <p class="mt-6 text-center text-sm">
        <.link
          href={~p"/users/log_in"}
          class="font-semibold text-gray-800 underline decoration-red-600 underline-offset-4 hover:text-red-700"
        >Back to log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"), page_title: "Forgot password")}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Users.get_user_by_email(email) do
      Users.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
