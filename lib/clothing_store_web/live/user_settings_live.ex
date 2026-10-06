defmodule ClothingStoreWeb.UserSettingsLive do
  use ClothingStoreWeb, :live_view

  import ClothingStoreWeb.Helpers, only: [password_requirements: 2]

  alias ClothingStore.Users

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.header>
        Account Settings
        <:subtitle>Manage your account email address and password settings.</:subtitle>
      </.header>

      <p
        :if={ClothingStore.Demo.locked?(@current_user)}
        class="mb-6 flex gap-3 rounded-md bg-amber-50 p-4 text-sm text-amber-900 ring-1 ring-amber-600/20"
      >
        <.icon name="hero-lock-closed-mini" class="size-5 shrink-0 text-amber-600" />
        This is the shared demo account, so its e-mail and password can't be changed.
      </p>

      <div class="space-y-6">
        <section class="card grid gap-6 p-6 sm:p-8 md:grid-cols-3" aria-labelledby="email-title">
          <div>
            <h2 id="email-title" class="font-semibold text-gray-900">Email address</h2>
            <p class="mt-1 text-sm text-gray-600">We send a confirmation link to the new address.</p>
          </div>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="md:col-span-2"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label="Email"
              autocomplete="email"
              required
            />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label="Current password"
              value={@email_form_current_password}
              autocomplete="current-password"
              required
            />
            <:actions>
              <.button phx-disable-with="Changing..." icon="hero-envelope" class="ml-auto">
                Change Email
              </.button>
            </:actions>
          </.simple_form>
        </section>

        <section class="card grid gap-6 p-6 sm:p-8 md:grid-cols-3" aria-labelledby="password-title">
          <div>
            <h2 id="password-title" class="font-semibold text-gray-900">Password</h2>
            <p class="mt-1 text-sm text-gray-600">Changing it logs out your other sessions.</p>
          </div>
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="md:col-span-2"
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label="New password"
              autocomplete="new-password"
              required
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              autocomplete="new-password"
            />
            <.requirements
              id="password-requirements"
              items={
                password_requirements(
                  @password_form[:password].value,
                  @password_form[:password_confirmation].value
                )
              }
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current password"
              id="current_password_for_password"
              value={@current_password}
              autocomplete="current-password"
              required
            />
            <:actions>
              <.button phx-disable-with="Changing..." icon="hero-key" class="ml-auto">
                Change Password
              </.button>
            </:actions>
          </.simple_form>
        </section>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Users.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Users.change_user_email(user)
    password_changeset = Users.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:page_title, "Settings")

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Users.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Users.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Users.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Users.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Users.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Users.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
