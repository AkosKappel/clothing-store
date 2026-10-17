defmodule ClothingStoreWeb.ProductComponents do
  @moduledoc "Badges for product data shared by the dashboard, inventory and statistics pages."
  use Phoenix.Component
  use Gettext, backend: ClothingStoreWeb.Gettext

  import ClothingStoreWeb.CoreComponents

  alias ClothingStore.Products.Product
  alias Phoenix.LiveView.JS

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

  @doc "The stock of each size (and colour) as small chips; sold-out sizes are struck through."
  attr :variants, :list, required: true

  def variant_stock(assigns) do
    ~H"""
    <ul :if={@variants != []} class="flex flex-wrap gap-1.5" aria-label={gettext("Stock per size")}>
      <li
        :for={variant <- @variants}
        class={[
          "rounded-md px-2 py-1 text-xs ring-1 ring-inset",
          if(variant.stock == 0,
            do: "text-gray-500 line-through ring-gray-200",
            else: "text-gray-800 ring-gray-300"
          )
        ]}
      >
        <span class="font-semibold">{variant.size}</span>{if variant.colour,
          do: " #{variant.colour}"}: {variant.stock}
      </li>
    </ul>
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
  attr :removable_tags, :boolean, default: false, doc: "× buttons on tag chips (LiveView only)"
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
          <p class="font-semibold">
            {gettext("The product couldn't be saved. Please fix the errors below.")}
          </p>
          <p :for={msg <- translate_errors(@form.errors, :base)} class="mt-1">{msg}</p>
        </div>
      </div>

      <.input
        field={@form[:title]}
        type="text"
        label={gettext("Title")}
        maxlength="100"
        counter
        required
      />
      <.input
        field={@form[:description]}
        type="textarea"
        label={gettext("Description")}
        maxlength="2000"
        rows="4"
        counter
        required
      />
      <.input
        field={@form[:photo]}
        type="text"
        label={gettext("Photo")}
        placeholder="/images/products/white-t-shirt.webp"
        hint={
          gettext("A path under /images/, or an https:// URL from %{hosts}.",
            hosts: ClothingStore.Products.Product.photo_hosts_text()
          )
        }
        required
      />
      <img
        :if={photo_preview?(@form[:photo])}
        id="photo-preview"
        src={@form[:photo].value}
        alt={gettext("Photo preview")}
        class="size-32 rounded-md bg-gray-100 object-cover ring-1 ring-gray-200"
      />

      <div class="grid grid-cols-1 gap-5 sm:grid-cols-3">
        <.input
          field={@form[:category]}
          type="text"
          label={gettext("Category")}
          maxlength="50"
          required
        />
        <.input
          field={@form[:price]}
          type="number"
          label={gettext("Price")}
          prefix="€"
          min="0"
          step="0.01"
          required
        />
        <div class="flex items-start gap-1.5">
          <div class="min-w-0 flex-1">
            <.input
              field={@form[:stock]}
              type="number"
              label={gettext("Stock")}
              min="0"
              step="1"
              required
              readonly={has_variants?(@form)}
              hint={has_variants?(@form) && gettext("The total of the sizes below")}
            />
          </div>
          <button
            :for={
              {step, icon, label} <- [
                {-1, "hero-minus-mini", gettext("Decrease stock")},
                {1, "hero-plus-mini", gettext("Increase stock")}
              ]
            }
            type="button"
            data-step={step}
            data-step-target={@form[:stock].id}
            aria-label={label}
            title={label}
            class="mt-7 rounded-md p-2 text-gray-700 ring-1 ring-gray-300 ring-inset hover:bg-gray-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
          >
            <.icon name={icon} class="size-5" />
          </button>
        </div>
      </div>

      <.input
        field={@form[:tags]}
        type="text"
        label={gettext("Tags")}
        value={@form[:tags].value |> List.wrap() |> Enum.join(", ")}
        hint={gettext("Comma separated or Enter after each, up to 10, for example: summer, sale")}
        data-tag-input
      />
      <ul
        :if={tag_list(@form) != []}
        class="-mt-3 flex flex-wrap gap-1.5"
        aria-label={gettext("Tags")}
      >
        <li
          :for={tag <- tag_list(@form)}
          class="inline-flex items-center gap-1 rounded-full bg-gray-100 py-0.5 pr-1 pl-2.5 text-xs font-medium text-gray-700 ring-1 ring-gray-200 ring-inset"
        >
          {tag}
          <button
            :if={@removable_tags}
            type="button"
            phx-click="remove_tag"
            phx-value-tag={tag}
            class="rounded-full p-0.5 hover:bg-gray-200 focus-visible:outline-2 focus-visible:outline-red-600"
            aria-label={gettext("Remove tag %{tag}", tag: tag)}
          >
            <.icon name="hero-x-mark-mini" class="size-3.5" />
          </button>
        </li>
      </ul>

      <fieldset class="rounded-md border border-gray-200 p-4">
        <legend class="px-1 text-sm font-semibold text-gray-800">
          {gettext("Sizes and colours (optional)")}
        </legend>
        <p class="mb-3 text-xs text-gray-500">
          {gettext("With sizes, each has its own stock and the product's stock is their total.")}
        </p>
        <.inputs_for :let={variant} field={@form[:variants]}>
          <input type="hidden" name="product[variants_sort][]" value={variant.index} />
          <div class="mb-3 grid grid-cols-[minmax(0,1fr)_minmax(0,1.5fr)_minmax(0,1fr)_auto] items-start gap-2">
            <.input field={variant[:size]} label={gettext("Size")} maxlength="10" required />
            <.input field={variant[:colour]} label={gettext("Colour")} maxlength="30" />
            <.input
              field={variant[:stock]}
              type="number"
              label={gettext("Stock")}
              min="0"
              step="1"
              required
            />
            <button
              type="button"
              name="product[variants_drop][]"
              value={variant.index}
              phx-click={JS.dispatch("change")}
              aria-label={gettext("Remove size %{size}", size: variant[:size].value)}
              title={gettext("Remove")}
              class="mt-7 rounded-md p-2 text-gray-600 ring-1 ring-gray-300 ring-inset hover:bg-gray-50 hover:text-red-700 focus-visible:outline-2 focus-visible:outline-red-600"
            >
              <.icon name="hero-trash-mini" class="size-5" />
            </button>
          </div>
        </.inputs_for>
        <input type="hidden" name="product[variants_drop][]" />
        <.button
          type="button"
          name="product[variants_sort][]"
          value="new"
          phx-click={JS.dispatch("change")}
          variant="secondary"
          size="sm"
          icon="hero-plus"
        >
          {gettext("Add a size")}
        </.button>
      </fieldset>

      <fieldset class="rounded-md border border-gray-200 p-4">
        <legend class="px-1 text-sm font-semibold text-gray-800">
          {gettext("Discount (optional)")}
        </legend>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <.input
            field={@form[:discount_percent]}
            type="number"
            label={gettext("Percent off")}
            min="1"
            max="90"
            step="1"
          />
          <.input field={@form[:discount_starts_on]} type="date" label={gettext("From")} />
          <.input field={@form[:discount_ends_on]} type="date" label={gettext("Until (inclusive)")} />
        </div>
        <p class="mt-2 text-xs text-gray-500">
          {gettext(
            "Sales during these days use the discounted price. Leave the percent empty for no discount."
          )}
        </p>
      </fieldset>

      <:actions>
        <div class="ml-auto flex flex-wrap items-center gap-3 border-t border-gray-100 pt-5">
          <.button navigate={@cancel_to} variant="secondary">{gettext("Cancel")}</.button>
          <.button type="submit" icon="hero-check" phx-disable-with={gettext("Saving...")}>
            {gettext("Save product")}
          </.button>
        </div>
      </:actions>
    </.simple_form>
    """
  end

  defp has_variants?(form), do: match?([_ | _], form[:variants].value)

  defp tag_list(form), do: form[:tags].value |> List.wrap() |> Enum.filter(&is_binary/1)

  # only a photo that passed validation, so the preview never requests an arbitrary URL
  defp photo_preview?(%Phoenix.HTML.FormField{value: value, errors: errors}),
    do: is_binary(value) and value != "" and errors == []

  @doc """
  A product's price: while a discount runs, the sale price, the struck list price
  and the percentage off.
  """
  attr :product, ClothingStore.Products.Product, required: true
  attr :class, :any, default: nil

  def price(assigns) do
    assigns = assign(assigns, :on_sale, Product.on_sale?(assigns.product))

    ~H"""
    <span class={["inline-flex flex-wrap items-baseline justify-end gap-x-1.5", @class]}>
      <span class={[
        "font-semibold whitespace-nowrap",
        if(@on_sale, do: "text-red-700", else: "text-gray-900")
      ]}>
        {ClothingStoreWeb.Helpers.format_price(Product.sale_price(@product))}
      </span>
      <s :if={@on_sale} class="text-sm whitespace-nowrap text-gray-500">
        <span class="sr-only">{gettext("was")}</span> {ClothingStoreWeb.Helpers.format_price(
          @product.price
        )}
      </s>
      <.badge :if={@on_sale} class="bg-red-50 text-red-800 ring-red-600/20">
        −{@product.discount_percent} %
      </.badge>
    </span>
    """
  end

  @doc "A QR code of `url` as inline SVG, labelled for screen readers."
  attr :url, :string, required: true
  attr :label, :string, required: true
  attr :class, :any, default: nil

  def qr_code(assigns) do
    assigns = assign(assigns, :svg, qr_svg(assigns.url))

    ~H"""
    <div role="img" aria-label={@label} class={["[&>svg]:size-full", @class]}>{@svg}</div>
    """
  end

  # the SVG is generated from our own URL, never from visitor input
  # sobelow_skip ["XSS.Raw"]
  defp qr_svg(url) do
    url
    |> EQRCode.encode()
    |> EQRCode.svg(viewbox: true)
    |> String.replace(~r/\A<\?xml[^>]*>\s*/, "")
    |> Phoenix.HTML.raw()
  end

  def stock_text(0), do: gettext("Out of stock")
  def stock_text(stock) when stock <= @low_stock, do: gettext("Low: %{stock} left", stock: stock)
  def stock_text(stock), do: gettext("%{stock} in stock", stock: stock)

  defp stock_class(0), do: "bg-red-50 text-red-800 ring-red-600/20"

  defp stock_class(stock) when stock <= @low_stock,
    do: "bg-amber-50 text-amber-800 ring-amber-600/20"

  defp stock_class(_stock), do: "bg-emerald-50 text-emerald-800 ring-emerald-600/20"
end
