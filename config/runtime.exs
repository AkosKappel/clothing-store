import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/clothing_store start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :clothing_store, ClothingStoreWeb.Endpoint, server: true
end

# Demo settings: only override the defaults from config.exs with env vars that are set
# (Config deep-merges keyword lists).
present = fn list -> Enum.reject(list, fn {_, v} -> v in [nil, ""] end) end

if config_env() == :prod and System.get_env("ADMIN_PASSWORD") in [nil, ""] do
  raise "environment variable ADMIN_PASSWORD is missing"
end

demo_account =
  present.(
    email: System.get_env("ADMIN_EMAIL"),
    password: System.get_env("ADMIN_PASSWORD")
  )

demo_reset =
  present.(
    enabled:
      if(config_env() == :test or System.get_env("DEMO_RESET_ENABLED") in [nil, ""],
        do: nil,
        else: System.get_env("DEMO_RESET_ENABLED") in ~w(true 1)
      ),
    time: System.get_env("DEMO_RESET_TIME"),
    timezone: System.get_env("DEMO_RESET_TIMEZONE")
  )

config :clothing_store, :demo, account: demo_account, reset: demo_reset

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :clothing_store, ClothingStore.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || raise "environment variable PHX_HOST is missing"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :clothing_store, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :clothing_store, ClothingStoreWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    # LiveView's websocket must come from the public host, or from the local test port
    check_origin: ["//#{host}", "//127.0.0.1", "//localhost"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  # Nothing is sent: e-mails (e.g. change-email links) are written to the log.
  config :clothing_store, ClothingStore.Mailer, adapter: Swoosh.Adapters.Logger, level: :info

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :clothing_store, ClothingStoreWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :clothing_store, ClothingStoreWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :clothing_store, ClothingStore.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
