defmodule ClothingStoreWeb.CoreComponents do
  @moduledoc """
  Provides core UI components: buttons, forms, tables, page headers,
  empty states and the delete confirmation dialog.

  The components use Tailwind CSS. Shared colours: gray for neutrals, red-600
  for the brand and primary actions, rose for errors.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: ClothingStoreWeb.Gettext

  alias Phoenix.LiveView.JS

  @focus_ring "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :auto_dismiss, :boolean, default: false, doc: "fade out after a few seconds (see app.css)"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={if @auto_dismiss, do: "#{@id}-#{:erlang.phash2(msg)}", else: @id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide({:closest, "[role=alert]"})}
      role="alert"
      class={[
        "fixed right-4 bottom-4 z-50 flex w-[calc(100%-2rem)] gap-3 rounded-lg p-4 shadow-lg ring-1 sm:w-96",
        "motion-safe:transition motion-safe:starting:translate-y-2 motion-safe:starting:opacity-0",
        @auto_dismiss && "toast-auto-dismiss",
        @kind == :info && "bg-emerald-50 text-emerald-900 ring-emerald-600/30",
        @kind == :error && "bg-rose-50 text-rose-900 ring-rose-600/30"
      ]}
      {@rest}
    >
      <.icon
        name={if @kind == :info, do: "hero-check-circle-mini", else: "hero-exclamation-circle-mini"}
        class={[
          "mt-0.5 shrink-0",
          @kind == :info && "text-emerald-600",
          @kind == :error && "text-rose-600"
        ]}
      />
      <div class="min-w-0 flex-1 text-sm">
        <p :if={@title} class="font-semibold">{@title}</p>
        <p class={@title && "mt-1"}>{msg}</p>
      </div>
      <button
        type="button"
        class="-m-1 h-fit rounded-sm p-1 opacity-60 hover:opacity-100"
        aria-label={gettext("close")}
        title={gettext("Close")}
      >
        <.icon name="hero-x-mark-mini" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} auto_dismiss />
      <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-5">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="flex flex-wrap items-center justify-between gap-4 pt-1">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button, or a link styled as one when `href`, `navigate` or `patch` is given.

  While its form submits, a button with an `icon` swaps the icon for a spinner
  (LiveView sets `phx-submit-loading`; `app.js` does the same for regular forms).

  ## Examples

      <.button>Send!</.button>
      <.button variant="secondary" icon="hero-pencil-square" navigate={~p"/products/1/edit"}>Edit</.button>
      <.button variant="danger" icon="hero-trash" phx-click="delete">Delete</.button>
  """
  attr :type, :string, default: nil
  attr :variant, :string, default: "primary", values: ~w(primary secondary danger)
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :icon, :string, default: nil, doc: "a heroicon name shown before the label"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(disabled form name value href navigate patch method download commandfor command)

  slot :inner_block, required: true

  def button(assigns) do
    assigns =
      assign(assigns, :classes, [
        "inline-flex items-center justify-center gap-1.5 rounded-md font-semibold whitespace-nowrap shadow-xs transition-colors",
        "disabled:cursor-not-allowed disabled:opacity-60 phx-submit-loading:cursor-wait phx-submit-loading:opacity-75",
        @focus_ring,
        case assigns.size do
          "sm" -> "px-2.5 py-1.5 text-sm"
          "md" -> "px-4 py-2 text-sm"
        end,
        case assigns.variant do
          "primary" -> "bg-red-600 text-white hover:bg-red-700"
          "secondary" -> "bg-white text-gray-800 ring-1 ring-gray-300 ring-inset hover:bg-gray-50"
          "danger" -> "bg-white text-red-700 ring-1 ring-red-300 ring-inset hover:bg-red-50"
        end,
        assigns.class
      ])

    if assigns.rest[:href] || assigns.rest[:navigate] || assigns.rest[:patch] do
      ~H"""
      <.link class={@classes} {@rest}>
        <.icon :if={@icon} name={@icon} class="size-4" />
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button type={@type} class={@classes} {@rest}>
        <.icon :if={@icon} name={@icon} class="size-4 phx-submit-loading:hidden" />
        <.icon
          :if={@icon}
          name="hero-arrow-path"
          class="hidden size-4 motion-safe:animate-spin phx-submit-loading:inline-block"
        />
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label, hint and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  Errors show only once the field was used (see `Phoenix.Component.used_input?/1`),
  and are linked to the input with `aria-describedby`.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :hint, :string, default: nil, doc: "help text shown below the input"
  attr :counter, :boolean, default: false, doc: "show the length against `maxlength`"
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-2 text-sm text-gray-700">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="size-4 rounded-sm border-gray-300 text-red-600 focus:ring-red-600"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[input_classes(@errors), "bg-white"]}
        multiple={@multiple}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={describedby(@id, @hint, @errors)}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.hint :if={@hint} id={"#{@id}-hint"}>{@hint}</.hint>
      <.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[input_classes(@errors), "min-h-28"]}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={describedby(@id, @hint, @errors)}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.counter :if={@counter} value={@value} max={@rest[:maxlength]} />
      <.hint :if={@hint} id={"#{@id}-hint"}>{@hint}</.hint>
      <.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</.error>
    </div>
    """
  end

  # The show/hide toggle sits next to the text field, not on top of it, so the
  # icons password managers put at the field's right edge never cover it.
  def input(%{type: "password"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} for={@id}>{@label}</.label>
      <div class={[
        "mt-1.5 flex rounded-md bg-white shadow-xs ring-1 ring-inset focus-within:ring-2",
        if(@errors == [],
          do: "ring-gray-300 focus-within:ring-red-600",
          else: "ring-rose-400 focus-within:ring-rose-500"
        )
      ]}>
        <input
          type="password"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value("password", @value)}
          class="block w-full min-w-0 flex-1 rounded-l-md border-0 bg-transparent text-gray-900 focus:ring-0 sm:text-sm/6"
          aria-invalid={@errors != [] && "true"}
          aria-describedby={describedby(@id, @hint, @errors)}
          {@rest}
        />
        <button
          type="button"
          class="flex shrink-0 items-center rounded-r-md border-l border-gray-200 px-3 text-gray-500 hover:bg-gray-50 hover:text-gray-800 focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-red-600"
          aria-label={gettext("Show password")}
          aria-pressed="false"
          aria-controls={@id}
          title={gettext("Show or hide the password")}
          phx-click={
            JS.toggle_attribute({"type", "text", "password"}, to: "##{@id}")
            |> JS.toggle_attribute({"aria-pressed", "true", "false"})
            |> JS.toggle_class("hidden", to: {:inner, "[data-eye]"})
          }
        >
          <.icon name="hero-eye-mini" data-eye />
          <.icon name="hero-eye-slash-mini" class="hidden" data-eye />
        </button>
      </div>
      <.hint :if={@hint} id={"#{@id}-hint"}>{@hint}</.hint>
      <.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label :if={@label} for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={input_classes(@errors)}
        aria-invalid={@errors != [] && "true"}
        aria-describedby={describedby(@id, @hint, @errors)}
        {@rest}
      />
      <.counter :if={@counter} value={@value} max={@rest[:maxlength]} />
      <.hint :if={@hint} id={"#{@id}-hint"}>{@hint}</.hint>
      <.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</.error>
    </div>
    """
  end

  defp input_classes(errors) do
    [
      "mt-1.5 block w-full rounded-md text-gray-900 shadow-xs sm:text-sm/6",
      if(errors == [],
        do: "border-gray-300 focus:border-red-600 focus:ring-red-600",
        else: "border-rose-400 focus:border-rose-500 focus:ring-rose-500"
      )
    ]
  end

  attr :value, :any, required: true
  attr :max, :any, required: true

  defp counter(assigns) do
    length = assigns.value |> to_string() |> String.length()
    max = String.to_integer(to_string(assigns.max))
    assigns = assign(assigns, length: length, max: max)

    ~H"""
    <p class={[
      "mt-1 text-right text-xs tabular-nums",
      if(@length >= @max * 0.9, do: "text-amber-700", else: "text-gray-500")
    ]}>
      {@length}/{@max}
    </p>
    """
  end

  defp describedby(id, hint, errors) do
    ids = [hint && "#{id}-hint", errors != [] && "#{id}-error"] |> Enum.filter(& &1)
    if ids != [], do: Enum.join(ids, " ")
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold text-gray-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  attr :id, :string, default: nil
  slot :inner_block, required: true

  defp hint(assigns) do
    ~H"""
    <p id={@id} class="mt-1.5 text-sm text-gray-500">{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Generates a generic error message.
  """
  attr :id, :string, default: nil
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p id={@id} class="mt-1.5 flex gap-1.5 text-sm text-rose-700">
      <.icon name="hero-exclamation-circle-mini" class="mt-px size-5 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a list of requirements, each ticked once it is met, for example
  the password rules while the user types.

  ## Examples

      <.requirements id="password-rules" items={[{"At least 12 characters", true}]} />
  """
  attr :id, :string, required: true
  attr :items, :list, required: true, doc: "`{label, met?}` tuples"

  def requirements(assigns) do
    ~H"""
    <ul id={@id} class="mt-2 space-y-1 text-sm">
      <li
        :for={{label, met} <- @items}
        class={["flex items-center gap-1.5", if(met, do: "text-emerald-700", else: "text-gray-500")]}
      >
        <.icon name={if met, do: "hero-check-circle-mini", else: "hero-minus-circle-mini"} />
        {label}
        <span class="sr-only">{if met, do: gettext("(done)"), else: gettext("(not yet)")}</span>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a page header with title, optional subtitle and actions.
  """
  attr :class, :any, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={["mb-8 flex flex-wrap items-end justify-between gap-4", @class]}>
      <div class="min-w-0">
        <h1 class="font-display text-2xl font-bold text-gray-900 sm:text-3xl">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-1 text-gray-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="flex flex-wrap items-center gap-3">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table, or the `:empty` slot when there are no rows.

  Below the `lg` breakpoint each row becomes a card: the first column is its heading and the
  other cells are listed with their column label (see `.responsive-table`).

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="ID">{user.id}</:col>
        <:col :let={user} label="Username">{user.username}</:col>
        <:empty>No users yet.</:empty>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"
  slot :empty, doc: "shown instead of the table when there are no rows"

  def table(assigns) do
    ~H"""
    <div :if={@rows == [] && @empty != []}>{render_slot(@empty)}</div>
    <div :if={@rows != [] || @empty == []} class="card overflow-x-auto">
      <table class="responsive-table min-w-full divide-y divide-gray-200 text-sm">
        <thead class="bg-gray-50 text-left">
          <tr>
            <th
              :for={col <- @col}
              scope="col"
              class={["px-4 py-3 font-semibold text-gray-700", col[:class]]}
            >
              {col[:label]}
            </th>
            <th :if={@action != []} scope="col" class="px-4 py-3">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id} class="divide-y divide-gray-200 bg-white">
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="hover:bg-gray-50">
            <td
              :for={col <- @col}
              data-label={col[:label]}
              class={["px-4 py-3 align-middle text-gray-700", col[:class]]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="px-4 py-3">
              <div class="flex items-center justify-end gap-2">
                {render_slot(@action, @row_item.(row))}
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class="divide-y divide-gray-100">
      <div :for={item <- @item} class="grid gap-1 py-3 text-sm sm:grid-cols-3 sm:gap-4">
        <dt class="font-medium text-gray-500">{item.title}</dt>
        <dd class="text-gray-900 sm:col-span-2">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  @doc """
  Renders an empty state: an icon, a title, a short explanation and optional actions.

  ## Examples

      <.empty_state icon="hero-cube" title="No products yet">
        Add the first product to get started.
        <:actions><.button navigate={~p"/products/new"}>New product</.button></:actions>
      </.empty_state>
  """
  attr :icon, :string, default: "hero-inbox"
  attr :image, :string, default: nil, doc: "an illustration shown instead of the icon"
  attr :title, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block
  slot :actions

  def empty_state(assigns) do
    ~H"""
    <div class={[
      "rounded-lg border-2 border-dashed border-gray-300 px-6 py-12 text-center",
      @class
    ]}>
      <img :if={@image} src={@image} alt="" class="mx-auto size-16 opacity-50 grayscale" />
      <.icon :if={!@image} name={@icon} class="size-10 text-gray-400" />
      <h2 class="mt-3 font-semibold text-gray-900">{@title}</h2>
      <p :if={@inner_block != []} class="mx-auto mt-1 max-w-md text-sm text-gray-600">
        {render_slot(@inner_block)}
      </p>
      <div :if={@actions != []} class="mt-6 flex flex-wrap justify-center gap-3">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a small pill, for example a product tag.

  `class` replaces the default gray colours, e.g. `class="bg-red-50 text-red-800 ring-red-600/20"`.
  """
  attr :class, :string, default: "bg-gray-100 text-gray-700 ring-gray-200"
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium whitespace-nowrap ring-1 ring-inset",
      @class
    ]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders a delete button that opens a confirmation dialog.

  The dialog is a native `<dialog>`, so focus trapping, Escape and the backdrop
  come from the browser. The confirm button submits a `DELETE` form to `action`.

  ## Examples

      <.delete_dialog id="delete-product" action={~p"/products/1"} title="Delete this product?">
        This can't be undone.
      </.delete_dialog>
  """
  attr :id, :string, required: true
  attr :action, :string, required: true
  attr :title, :string, required: true
  attr :label, :string, default: "Delete", doc: "the label of the trigger and confirm buttons"
  attr :size, :string, default: "md"
  slot :inner_block, required: true

  def delete_dialog(assigns) do
    ~H"""
    <.button
      type="button"
      variant="danger"
      size={@size}
      icon="hero-trash"
      commandfor={@id}
      command="show-modal"
    >
      {@label}
    </.button>
    <dialog
      id={@id}
      aria-labelledby={"#{@id}-title"}
      aria-describedby={"#{@id}-description"}
      closedby="any"
      class={[
        "m-auto w-[calc(100%-2rem)] max-w-md rounded-lg bg-white p-6 text-left shadow-xl backdrop:bg-gray-900/50",
        "motion-safe:transition-[opacity,scale] motion-safe:duration-150 motion-safe:starting:open:scale-95 motion-safe:starting:open:opacity-0"
      ]}
    >
      <div class="flex gap-4">
        <div class="flex size-10 shrink-0 items-center justify-center rounded-full bg-red-100">
          <.icon name="hero-exclamation-triangle" class="size-6 text-red-600" />
        </div>
        <div>
          <h2 id={"#{@id}-title"} class="font-semibold text-gray-900">{@title}</h2>
          <p id={"#{@id}-description"} class="mt-1 text-sm text-gray-600">
            {render_slot(@inner_block)}
          </p>
        </div>
      </div>
      <div class="mt-6 flex justify-end gap-3">
        <form method="dialog">
          <.button variant="secondary" autofocus>{gettext("Cancel")}</.button>
        </form>
        <.form for={%{}} action={@action} method="delete">
          <.button icon="hero-trash">{@label}</.button>
        </.form>
      </div>
    </dialog>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class="mb-4 inline-flex items-center gap-1 rounded-sm text-sm font-semibold text-gray-600 hover:text-gray-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
    >
      <.icon name="hero-arrow-left-mini" />
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" {@rest} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ClothingStoreWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ClothingStoreWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
