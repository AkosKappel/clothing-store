defmodule ClothingStoreWeb.ProductComponents do
  @moduledoc "Badges for product data shared by the dashboard, inventory and statistics pages."
  use Phoenix.Component

  import ClothingStoreWeb.CoreComponents

  @low_stock ClothingStore.Products.low_stock()

  # One colour per seed category, in the order of the validated default chart
  # palette (dataviz skill); any other category is "other" gray. The same colour
  # marks the category in badges and charts.
  @category_colors %{
    "Shirts & Tops" => "#2a78d6",
    "Trousers" => "#eb6834",
    "Dresses & Skirts" => "#1baf7a",
    "Knitwear" => "#eda100",
    "Jackets & Coats" => "#e87ba4",
    "Shoes" => "#008300",
    "Accessories" => "#4a3aa7",
    "Sportswear" => "#e34948"
  }
  @other_color "#8b8b86"

  @doc "The chart colour of a category (gray for categories outside the seed set)."
  def category_color(category), do: Map.get(@category_colors, category, @other_color)

  @doc "The colour for grouped, smaller categories in charts."
  def other_color, do: @other_color

  @doc "Stock as a coloured badge: in stock, low (#{@low_stock} or fewer) or out of stock."
  attr :stock, :integer, required: true

  def stock_badge(assigns) do
    ~H"""
    <.badge class={stock_class(@stock)}>{stock_text(@stock)}</.badge>
    """
  end

  @doc "A category badge with the category's chart colour as a dot."
  attr :category, :string, required: true

  def category_badge(assigns) do
    ~H"""
    <.badge>
      <svg class="mr-1.5 size-2" viewBox="0 0 8 8" aria-hidden="true">
        <circle cx="4" cy="4" r="4" fill={category_color(@category)} />
      </svg>
      {@category}
    </.badge>
    """
  end

  @doc """
  The product form. `ProductLive.Form` validates it live and then submits it to
  `ProductController`, which also renders it when saving fails on the server.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :cancel_to, :string, required: true
  attr :rest, :global, include: ~w(phx-trigger-action)

  def product_form(assigns) do
    ~H"""
    <.simple_form for={@form} action={@action} class="card p-6 sm:p-8" {@rest}>
      <div
        :if={@form.source.action in [:insert, :update] && @form.errors != []}
        role="alert"
        class="flex gap-3 rounded-md bg-rose-50 p-4 text-sm text-rose-900 ring-1 ring-rose-600/20"
      >
        <.icon name="hero-exclamation-circle-mini" class="size-5 shrink-0 text-rose-600" />
        <div>
          <p class="font-semibold">The product couldn't be saved. Please fix the errors below.</p>
          <p :for={msg <- translate_errors(@form.errors, :base)} class="mt-1">{msg}</p>
        </div>
      </div>

      <.input field={@form[:title]} type="text" label="Title" maxlength="100" counter required />
      <.input
        field={@form[:description]}
        type="textarea"
        label="Description"
        maxlength="2000"
        rows="4"
        counter
        required
      />
      <.input
        field={@form[:photo]}
        type="text"
        label="Photo"
        placeholder="/images/products/white-t-shirt.webp"
        hint={"A path under /images/, or an https:// URL from #{ClothingStore.Products.Product.photo_hosts_text()}."}
        required
      />

      <div class="grid grid-cols-1 gap-5 sm:grid-cols-3">
        <.input field={@form[:category]} type="text" label="Category" maxlength="50" required />
        <.input field={@form[:price]} type="number" label="Price (€)" min="0" step="0.01" required />
        <.input field={@form[:stock]} type="number" label="Stock" min="0" step="1" required />
      </div>

      <.input
        field={@form[:tags]}
        type="text"
        label="Tags"
        value={@form[:tags].value |> List.wrap() |> Enum.join(", ")}
        hint="Comma separated, up to 10, for example: summer, sale"
      />

      <:actions>
        <div class="ml-auto flex flex-wrap items-center gap-3 border-t border-gray-100 pt-5">
          <.button href={@cancel_to} variant="secondary">Cancel</.button>
          <.button type="submit" icon="hero-check" phx-disable-with="Saving...">
            Save product
          </.button>
        </div>
      </:actions>
    </.simple_form>
    """
  end

  def stock_text(0), do: "Out of stock"
  def stock_text(stock) when stock <= @low_stock, do: "Low: #{stock} left"
  def stock_text(stock), do: "#{stock} in stock"

  defp stock_class(0), do: "bg-red-50 text-red-800 ring-red-600/20"

  defp stock_class(stock) when stock <= @low_stock,
    do: "bg-amber-50 text-amber-800 ring-amber-600/20"

  defp stock_class(_stock), do: "bg-emerald-50 text-emerald-800 ring-emerald-600/20"
end
