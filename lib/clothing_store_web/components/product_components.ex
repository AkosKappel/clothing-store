defmodule ClothingStoreWeb.ProductComponents do
  @moduledoc "Badges for product data shared by the dashboard, inventory and statistics pages."
  use Phoenix.Component

  import ClothingStoreWeb.CoreComponents

  @low_stock 5

  # literal class strings so Tailwind can see them
  @category_colors [
    "bg-sky-50 text-sky-800 ring-sky-600/20",
    "bg-violet-50 text-violet-800 ring-violet-600/20",
    "bg-amber-50 text-amber-800 ring-amber-600/20",
    "bg-teal-50 text-teal-800 ring-teal-600/20",
    "bg-pink-50 text-pink-800 ring-pink-600/20",
    "bg-indigo-50 text-indigo-800 ring-indigo-600/20"
  ]

  @doc "Stock as a coloured badge: in stock, low (#{@low_stock} or fewer) or out of stock."
  attr :stock, :integer, required: true

  def stock_badge(assigns) do
    ~H"""
    <.badge class={stock_class(@stock)}>{stock_text(@stock)}</.badge>
    """
  end

  @doc "A category badge whose colour is stable for the same category name."
  attr :category, :string, required: true

  def category_badge(assigns) do
    ~H"""
    <.badge class={category_class(@category)}>{@category}</.badge>
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

  defp category_class(category),
    do: Enum.at(@category_colors, :erlang.phash2(category, length(@category_colors)))
end
