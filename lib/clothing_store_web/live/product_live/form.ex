defmodule ClothingStoreWeb.ProductLive.Form do
  @moduledoc """
  New and edit product forms. They validate as you type; a valid form is then
  submitted to `ProductController` (`phx-trigger-action`), so saving goes
  through the same rate-limited HTTP route as before.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Products
  alias ClothingStore.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.back navigate={@back_to}>{@back_label}</.back>
      <.header>
        {@page_heading}
        <:subtitle>{@subtitle}</:subtitle>
      </.header>

      <.product_form
        form={@form}
        action={@action}
        cancel_to={@back_to}
        id="product-form"
        phx-change="validate"
        phx-submit="save"
        phx-trigger-action={@trigger_submit}
      />
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket |> assign(:trigger_submit, false) |> apply_action(socket.assigns.live_action, params)}
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

  defp assign_form(socket, params, action) do
    params = Map.update(params, "tags", [], &Products.parse_tags/1)

    changeset =
      socket.assigns.product
      |> Products.change_product(params)
      |> Map.put(:action, action)

    assign(socket, :form, to_form(changeset))
  end
end
