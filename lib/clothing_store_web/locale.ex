defmodule ClothingStoreWeb.Locale do
  @moduledoc """
  The interface language: English, German or Slovak, from the `locale` cookie.

  `?locale=de` (the header's language links) sets the cookie and redirects back
  without the parameter. The plug copies the choice into the session, where the
  `on_mount` hook picks it up for LiveViews, which can't read cookies.
  """
  import Plug.Conn

  @locales ~w(en de sk)
  @max_age 365 * 24 * 60 * 60

  def locales, do: @locales

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _opts) when locale in @locales do
    query = conn.query_params |> Map.delete("locale") |> URI.encode_query()

    conn
    |> put_resp_cookie("locale", locale, max_age: @max_age, same_site: "Lax")
    |> Phoenix.Controller.redirect(
      to: conn.request_path <> if(query == "", do: "", else: "?" <> query)
    )
    |> halt()
  end

  def call(conn, _opts) do
    locale = if conn.cookies["locale"] in @locales, do: conn.cookies["locale"], else: "en"
    Gettext.put_locale(ClothingStoreWeb.Gettext, locale)
    put_session(conn, :locale, locale)
  end

  def on_mount(:default, _params, session, socket) do
    if session["locale"] in @locales,
      do: Gettext.put_locale(ClothingStoreWeb.Gettext, session["locale"])

    {:cont, socket}
  end
end
