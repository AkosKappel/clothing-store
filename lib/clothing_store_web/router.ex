defmodule ClothingStoreWeb.Router do
  use ClothingStoreWeb, :router

  import ClothingStoreWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  # photos may come from the image hosts in ClothingStore.Products.Product.photo_hosts/0;
  # 'unsafe-inline' styles are for topbar, which styles its canvas from JS
  @csp Enum.join(
         [
           "default-src 'self'",
           "script-src 'self'",
           "style-src 'self' 'unsafe-inline'",
           "img-src 'self' data: " <>
             Enum.map_join(ClothingStore.Products.Product.photo_hosts(), " ", &"https://#{&1}"),
           "font-src 'self' data:",
           "connect-src 'self'",
           "object-src 'none'",
           "base-uri 'self'",
           "form-action 'self'",
           "frame-ancestors 'self'"
         ],
         "; "
       )

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug ClothingStoreWeb.Locale
    plug :put_root_layout, html: {ClothingStoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
    plug :fetch_current_user
  end

  # LiveDashboard's inline scripts carry a per-request nonce, allowed only on its pages
  pipeline :admin do
    plug :require_admin
    plug :put_admin_csp
  end

  defp put_admin_csp(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64()
    csp = String.replace(@csp, "script-src 'self'", "script-src 'self' 'nonce-#{nonce}'")
    conn |> assign(:csp_nonce, nonce) |> put_resp_header("content-security-policy", csp)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ClothingStoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    # on_mount assigns current_user, which the app layout's nav needs
    live_session :dashboard,
      on_mount: [
        {ClothingStoreWeb.UserAuth, :ensure_authenticated},
        {ClothingStoreWeb.Presence, :track}
      ] do
      live "/", ProductLive.Index, :index
      # the forms validate live and then post to ProductController, which nginx rate-limits
      live "/products/new", ProductLive.Form, :new
      live "/products/import", ProductLive.Import, :new
      live "/products/:id/edit", ProductLive.Form, :edit
      live "/products", ProductLive.Inventory, :index
      live "/products/:id", ProductLive.Show, :show
      live "/transactions", TransactionsLive, :index
      live "/statistics", StatisticsLive, :index
      live "/activity", ActivityLive, :index
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end

    get "/transactions.csv", PageController, :transactions_csv
    get "/inventory.csv", ProductController, :export

    resources "/products", ProductController, only: [:create, :update, :delete]
    post "/products/:id/restock", ProductController, :restock
    get "/products/:id/label", ProductController, :label
    post "/products/:id/restore", ProductController, :restore
    post "/products/:id/versions/:version_id/revert", ProductController, :revert
  end

  scope "/", ClothingStoreWeb do
    pipe_through :api

    get "/health", HealthController, :show, log: false
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:clothing_store, :dev_routes) do
    # LiveDashboard is at /admin/dashboard, for admins (OWNER_EMAIL / OWNER_PASSWORD)
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/admin" do
    pipe_through [:browser, :require_authenticated_user, :admin]

    live_dashboard "/dashboard",
      metrics: ClothingStoreWeb.Telemetry,
      csp_nonce_assign_key: %{script: :csp_nonce, style: :csp_nonce},
      on_mount: [{ClothingStoreWeb.UserAuth, :ensure_admin}],
      live_session_name: :admin_dashboard
  end

  ## Authentication routes

  scope "/", ClothingStoreWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ClothingStoreWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      # Disable refistration (only the admin can create users)
      # live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
    post "/users/demo_log_in", UserSessionController, :demo
  end

  scope "/", ClothingStoreWeb do
    pipe_through [:browser]

    get "/about", PageController, :about
    get "/privacy", PageController, :privacy
    get "/terms", PageController, :terms
    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ClothingStoreWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
      live "/system", SystemLive, :index
    end
  end
end
