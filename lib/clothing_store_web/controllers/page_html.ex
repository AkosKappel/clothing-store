defmodule ClothingStoreWeb.PageHTML do
  import ClothingStoreWeb.Helpers

  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ClothingStoreWeb, :html

  embed_templates "page_html/*"

  @link_labels %{
    github: "GitHub",
    linkedin: "LinkedIn",
    portfolio: "Portfolio",
    repository: "Source code of this project"
  }

  def link_label(key), do: Map.fetch!(@link_labels, key)

  @doc "The tasks of the original take-home assignment and where to see each one."
  def assignment_tasks do
    [
      %{
        name: "Product dashboard",
        required: true,
        text:
          "Add, edit and delete products with photo, title, description, category, price and stock, and filter the list.",
        path: ~p"/products"
      },
      %{
        name: "Inventory, transactions and statistics",
        required: true,
        text:
          "Stock levels, every transaction with a month filter, and the best-selling products.",
        path: ~p"/statistics"
      },
      %{
        name: "Login",
        required: false,
        text:
          "Every dashboard page sits behind a login. Registration is closed: the demo uses one shared account.",
        path: ~p"/users/log_in"
      },
      %{
        name: "Live feed",
        required: false,
        text:
          "Changes made by one visitor appear for everyone else straight away, using Phoenix PubSub.",
        path: ~p"/"
      },
      %{
        name: "Tags",
        required: false,
        text: "Products can carry several tags instead of a single category.",
        path: ~p"/products"
      },
      %{
        name: "Tag filter",
        required: false,
        text: "Filter by any combination of tags, together with the other filters.",
        path: ~p"/products"
      }
    ]
  end

  @doc ~S'["a", "b", "c"] -> "a, b or c"'
  def or_list([only]), do: only

  def or_list(items) do
    {init, [last]} = Enum.split(items, -1)
    Enum.join(init, ", ") <> " or " <> last
  end

  def reset_time(%{time: time}), do: Calendar.strftime(time, "%H:%M")
end
