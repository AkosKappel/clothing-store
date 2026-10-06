defmodule ClothingStoreWeb.UserConfirmationInstructionsLive do
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Users

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md pt-4 sm:pt-8">
      <.header class="justify-center text-center">
        No confirmation instructions received?
        <:subtitle>We'll send a new confirmation link to your inbox.</:subtitle>
      </.header>

      <div class="card p-6 sm:p-8">
        <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
          />
          <:actions>
            <.button phx-disable-with="Sending..." icon="hero-envelope" class="w-full">
              Resend confirmation instructions
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
    {:ok, assign(socket, form: to_form(%{}, as: "user"), page_title: "Resend confirmation")}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Users.get_user_by_email(email) do
      Users.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
