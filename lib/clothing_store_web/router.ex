defmodule ClothingStoreWeb.Router do
  use ClothingStoreWeb, :router

  import ClothingStoreWeb.UserAuth

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
    plug :put_root_layout, html: {ClothingStoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ClothingStoreWeb do
    pipe_through [:browser, :require_authenticated_user]

    # on_mount assigns current_user, which the app layout's nav needs
    live_session :dashboard, on_mount: [{ClothingStoreWeb.UserAuth, :ensure_authenticated}] do
      live "/", ProductLive.Index, :index
      # the forms validate live and then post to ProductController, which nginx rate-limits
      live "/products/new", ProductLive.Form, :new
      live "/products/:id/edit", ProductLive.Form, :edit
    end

    get "/transactions", PageController, :transactions
    get "/statistics", PageController, :statistics

    resources "/products", ProductController, except: [:new, :edit]
  end

  # Other scopes may use custom stacks.
  # scope "/api", ClothingStoreWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:clothing_store, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ClothingStoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
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
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ClothingStoreWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", ClothingStoreWeb do
    pipe_through [:browser]

    get "/about", PageController, :about
    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ClothingStoreWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
