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

  @doc "A ranked table of `{product, quantity_sold}` rows, or an empty state."
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :rows, :list, required: true
  attr :empty, :string, required: true

  def bestsellers(assigns) do
    ~H"""
    <section aria-labelledby={"#{@id}-title"}>
      <h2 id={"#{@id}-title"} class="mb-3 text-lg font-semibold text-gray-900">{@title}</h2>
      <.table id={@id} rows={Enum.with_index(@rows, 1)}>
        <:col :let={{_row, rank}} label="#" class="w-12 font-semibold text-gray-900">{rank}</:col>
        <:col :let={{{product, _sold}, _rank}} label="Product">
          <.link
            href={~p"/products/#{product}"}
            class="font-medium text-gray-900 hover:text-red-700 hover:underline"
          >
            {product.title}
          </.link>
        </:col>
        <:col :let={{{product, _sold}, _rank}} label="Price" class="text-right whitespace-nowrap">
          {format_price(product.price)}
        </:col>
        <:col :let={{{_product, sold}, _rank}} label="Sold" class="text-right whitespace-nowrap">
          {sold}
        </:col>
        <:col :let={{{product, _sold}, _rank}} label="In stock" class="text-right whitespace-nowrap">
          {product.stock}
        </:col>
        <:empty>
          <.empty_state icon="hero-chart-bar" title={@empty} class="py-8" />
        </:empty>
      </.table>
    </section>
    """
  end
end
