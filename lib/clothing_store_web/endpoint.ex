defmodule ClothingStoreWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :clothing_store

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_clothing_store_key",
    signing_salt: "N+R+6l9N",
    same_site: "Lax",
    secure: Application.compile_env(:clothing_store, :secure_cookies, false)
  ]

  socket "/live", Phoenix.LiveView.Socket,
    # LiveView messages are small; the adapter default (10 MB) lets one client hog memory
    websocket: [connect_info: [session: @session_options], max_frame_size: 1_000_000],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :clothing_store,
    gzip: not code_reloading?,
    only: ClothingStoreWeb.static_paths(),
    # digested favicons (favicon-<hash>.svg) don't match the exact names in static_paths
    only_matching: ~w(favicon)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :clothing_store
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug ClothingStoreWeb.Router
end
