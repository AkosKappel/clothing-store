defmodule ClothingStoreWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs. Error pages render without the app layout (the user
  may not be loaded), so `error_page/1` brings its own minimal page.
  """
  use ClothingStoreWeb, :html

  def render("404.html", _assigns) do
    error_page(%{
      status: 404,
      title: "Page not found",
      text:
        "The page you're looking for doesn't exist. Maybe the product was deleted, or the nightly reset removed it.",
      reference: nil
    })
  end

  def render("500.html", _assigns) do
    error_page(%{
      status: 500,
      title: "Something went wrong",
      text: "An unexpected error stopped this page. Please try again in a moment.",
      # the same id is in the log lines of this request, next to the stack trace
      reference: Logger.metadata()[:request_id]
    })
  end

  # The default is to render a plain text page based on
  # the template name. For example, "403.html" becomes
  # "Forbidden".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  defp error_page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" type="image/svg+xml" href={~p"/favicon.svg"} />
        <title>{@title} | Modern Fashion Store</title>
        <link rel="stylesheet" href={~p"/assets/css/app.css"} />
      </head>
      <body class="flex min-h-screen flex-col bg-gray-50 text-gray-900 antialiased">
        <header class="bg-gray-800">
          <div class="mx-auto flex max-w-7xl items-center px-4 py-3 sm:px-6 lg:px-8">
            <a href="/" class="flex items-center gap-2">
              <img src={~p"/images/logo.svg"} width="40" height="40" alt="" />
              <span class="font-display text-xl font-bold text-red-400 italic sm:text-2xl">
                Modern Fashion Store
              </span>
            </a>
          </div>
        </header>

        <main class="flex flex-1 items-center justify-center px-4 py-16">
          <div class="max-w-lg text-center">
            <p class="font-display text-6xl font-extrabold text-red-600">{@status}</p>
            <h1 class="mt-4 font-display text-3xl font-bold text-gray-900">{@title}</h1>
            <p class="mt-3 text-gray-600">{@text}</p>
            <p :if={@reference} class="mt-4 text-sm text-gray-500">
              Reference: <code class="font-mono">{@reference}</code>
            </p>
            <div class="mt-8 flex flex-wrap justify-center gap-3">
              <.button href="/" icon="hero-home">Go to the dashboard</.button>
              <.button href={~p"/about"} variant="secondary">About this project</.button>
            </div>
          </div>
        </main>
      </body>
    </html>
    """
  end
end
