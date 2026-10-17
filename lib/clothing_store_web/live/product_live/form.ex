defmodule ClothingStoreWeb.ProductLive.Form do
  @moduledoc """
  New and edit product forms. They validate as you type; a valid form is then
  submitted to `ProductController` (`phx-trigger-action`), so saving goes
  through the same rate-limited HTTP route as before.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Products
  alias ClothingStore.Products.Product
  alias ClothingStoreWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.back navigate={@back_to}>{@back_label}</.back>
      <.header>
        {@page_heading}
        <:subtitle>{@subtitle}</:subtitle>
      </.header>

      <p
        :if={@other_editors > 0}
        id="other-editors"
        role="status"
        class="mb-6 flex gap-3 rounded-md bg-amber-50 p-4 text-sm text-amber-900 ring-1 ring-amber-600/20"
      >
        <.icon name="hero-users-mini" class="size-5 shrink-0 text-amber-600" />
        {ngettext(
          "Another visitor is editing this product right now. If you both save, the last save wins.",
          "%{count} other visitors are editing this product right now. If you all save, the last save wins.",
          @other_editors
        )}
      </p>

      <.product_form
        form={@form}
        action={@action}
        cancel_to={@back_to}
        id="product-form"
        phx-change="validate"
        phx-submit="save"
        phx-trigger-action={@trigger_submit}
        removable_tags
      />
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(trigger_submit: false, other_editors: 0)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{}

    assign(socket,
      product: product,
      action: ~p"/products",
      back_to: ~p"/products",
      back_label: "Inventory",
      page_title: "New product",
      page_heading: "New Product",
      subtitle: "Add a product to the catalogue. All fields except tags are required.",
      form: to_form(Products.change_product(product))
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Products.get_product!(id)
    socket = track_editing(socket, product)

    assign(socket,
      product: product,
      action: ~p"/products/#{product}",
      back_to: ~p"/products/#{product}",
      back_label: product.title,
      page_title: "Edit product",
      page_heading: "Edit Product",
      subtitle: "Changes are shown to every visitor straight away.",
      form: to_form(Products.change_product(product))
    )
  end

  @impl true
  def handle_event("validate", %{"product" => params}, socket) do
    {:noreply, assign_form(socket, params, :validate)}
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    form = socket.assigns.form
    tags = form[:tags].value |> List.wrap() |> List.delete(tag)
    {:noreply, assign_form(socket, Map.put(form.params, "tags", tags), :validate)}
  end

  def handle_event("save", %{"product" => params}, socket) do
    action = if socket.assigns.live_action == :new, do: :insert, else: :update
    socket = assign_form(socket, params, action)
    changeset = socket.assigns.form.source

    cond do
      not changeset.valid? ->
        {:noreply, socket}

      action == :insert and Products.catalogue_full?() ->
        changeset =
          Ecto.Changeset.add_error(
            changeset,
            :base,
            "The demo is limited to #{Products.max_products()} products"
          )

        {:noreply, assign(socket, :form, to_form(changeset))}

      true ->
        {:noreply, assign(socket, :trigger_submit, true)}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket),
    do: {:noreply, count_other_editors(socket)}

  defp track_editing(socket, product) do
    if connected?(socket) do
      topic = Presence.editing_topic(product.id)
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, topic)
      Presence.track(self(), topic, socket.assigns.presence_key, %{})
      socket |> assign(:editing_topic, topic) |> count_other_editors()
    else
      socket
    end
  end

  defp count_other_editors(socket),
    do:
      assign(
        socket,
        :other_editors,
        Presence.others(socket.assigns.editing_topic, socket.assigns.presence_key)
      )

  defp assign_form(socket, params, action) do
    params = Map.update(params, "tags", [], &Products.parse_tags/1)

    changeset =
      socket.assigns.product
      |> Products.change_product(params)
      |> Map.put(:action, action)

    assign(socket, :form, to_form(changeset))
  end
end
