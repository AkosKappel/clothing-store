defmodule ClothingStoreWeb.UserResetPasswordLive do
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.Helpers, only: [password_requirements: 2]

  alias ClothingStore.Users

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md pt-4 sm:pt-8">
      <.header class="justify-center text-center">
        Reset Password
        <:subtitle>Choose a new password of at least 12 characters.</:subtitle>
      </.header>

      <div class="card p-6 sm:p-8">
        <.simple_form
          for={@form}
          id="reset_password_form"
          phx-submit="reset_password"
          phx-change="validate"
        >
          <.input
            field={@form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm new password"
            autocomplete="new-password"
            required
          />
          <.requirements
            id="password-requirements"
            items={
              password_requirements(
                @form[:password].value,
                @form[:password_confirmation].value
              )
            }
          />
          <:actions>
            <.button phx-disable-with="Resetting..." icon="hero-key" class="w-full">
              Reset Password
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

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Users.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, socket |> assign_form(form_source) |> assign(:page_title, "Reset password"),
     temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Users.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Users.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Users.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
