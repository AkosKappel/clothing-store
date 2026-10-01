defmodule ClothingStore.Demo do
  @moduledoc """
  Settings of the public demo: the shared demo account, the nightly reset and the
  author's details shown on the About page.
  """

  alias ClothingStore.Users.User

  def account do
    config = Application.fetch_env!(:clothing_store, :demo)[:account]
    %{email: Keyword.fetch!(config, :email), password: Keyword.fetch!(config, :password)}
  end

  @doc "The demo account's e-mail and password can't be changed."
  def locked?(%User{email: email}), do: email == account().email
  def locked?(_), do: false

  def reset_settings do
    config = Application.fetch_env!(:clothing_store, :demo)[:reset]

    %{
      enabled: Keyword.get(config, :enabled, false),
      time: Time.from_iso8601!(Keyword.fetch!(config, :time) <> ":00"),
      timezone: Keyword.fetch!(config, :timezone)
    }
  end

  @doc "The name of the project's author."
  def author, do: Application.fetch_env!(:clothing_store, :demo)[:author]

  @link_order [:github, :linkedin, :portfolio, :repository]

  @doc "The configured profile links, in a fixed order; empty ones are left out."
  def links do
    links = Application.fetch_env!(:clothing_store, :demo)[:links] || []

    for key <- @link_order, url = links[key], url not in [nil, ""], do: {key, url}
  end
end
