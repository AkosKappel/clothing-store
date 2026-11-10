defmodule ClothingStoreWeb.ProductLive.Form do
  @moduledoc """
  New and edit product forms. They validate as you type; a valid form is then
  submitted to `ProductController` (`phx-trigger-action`), so saving goes
  through the same rate-limited HTTP route as before.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.ActivityFeed
  alias ClothingStore.Products
  alias ClothingStore.Products.{Photos, Product}
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
          "Another visitor is editing this product right now. If they save first, you will be asked before your save replaces theirs.",
          "%{count} other visitors are editing this product right now. If one of them saves first, you will be asked before your save replaces theirs.",
          @other_editors
        )}
      </p>

      <div
        :if={@newer}
        id="newer-version"
        role="alert"
        class="mb-6 flex gap-3 rounded-md bg-amber-50 p-4 text-sm text-amber-900 ring-1 ring-amber-600/20"
      >
        <.icon name="hero-arrow-path-mini" class="size-5 shrink-0 text-amber-600" />
        <div class="flex flex-col gap-3">
          <p>
            {gettext("Someone else just saved this product.")}
            <span :if={@newer_fields != []}>
              {gettext("Changed: %{fields}.", fields: Enum.join(@newer_fields, ", "))}
            </span>
          </p>
          <div class="flex flex-wrap gap-2">
            <.button type="button" size="sm" phx-click="load_newer">
              {gettext("Load their version")}
            </.button>
            <.button type="button" size="sm" variant="secondary" phx-click="keep_mine">
              {gettext("Keep my changes")}
            </.button>
          </div>
        </div>
      </div>

      <.product_form
        form={@form}
        lock_version={@product.lock_version}
        photo_upload={@uploads.photo}
        photo_upload_error={@photo_upload_error}
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
     |> assign(
       trigger_submit: false,
       other_editors: 0,
       newer: nil,
       newer_fields: [],
       photo_upload_error: nil
     )
     |> allow_upload(:photo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 8_000_000,
       auto_upload: true,
       progress: &photo_progress/3
     )
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{}

    assign(socket,
      product: product,
      action: ~p"/products",
      back_to: ~p"/products",
      back_label: gettext("Inventory"),
      page_title: gettext("New product"),
      page_heading: gettext("New Product"),
      subtitle: gettext("Add a product to the catalogue. All fields except tags are required."),
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
      page_title: gettext("Edit product"),
      page_heading: gettext("Edit Product"),
      subtitle: gettext("Changes are shown to every visitor straight away."),
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

  def handle_event("load_newer", _params, socket) do
    product = socket.assigns.newer

    {:noreply,
     assign(socket,
       product: product,
       back_label: product.title,
       form: to_form(Products.change_product(product)),
       newer: nil,
       newer_fields: []
     )}
  end

  # the form's own values stay, now on top of the newer version, so saving replaces it
  def handle_event("keep_mine", _params, socket) do
    params = socket.assigns.form.params
    socket = assign(socket, product: socket.assigns.newer, newer: nil, newer_fields: [])

    # nothing typed yet: the newer version is what the form shows
    {:noreply,
     if(params == %{},
       do: assign(socket, :form, to_form(Products.change_product(socket.assigns.product))),
       else: assign_form(socket, params, :validate)
     )}
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
            gettext("The demo is limited to %{max} products", max: Products.max_products())
          )

        {:noreply, assign(socket, :form, to_form(changeset))}

      true ->
        {:noreply, assign(socket, :trigger_submit, true)}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket),
    do: {:noreply, count_other_editors(socket)}

  def handle_info(
        {:product_updated, %Product{id: id} = newer},
        %{assigns: %{product: %{id: id}}} = socket
      )
      when newer.lock_version > socket.assigns.product.lock_version do
    fields = socket.assigns.product |> ActivityFeed.changes(newer) |> Map.keys()
    {:noreply, assign(socket, newer: newer, newer_fields: Enum.map(fields, &field_label/1))}
  end

  # other products, and the nightly reset (which ends the session anyway)
  def handle_info({event, _product}, socket)
      when event in [:product_created, :product_updated, :product_deleted],
      do: {:noreply, socket}

  def handle_info(:demo_reset, socket), do: {:noreply, socket}

  # once the file is in, it is re-encoded and its path goes into the photo field
  defp photo_progress(:photo, %{done?: false}, socket), do: {:noreply, socket}

  # the path is LiveView's own temporary file for the upload
  # sobelow_skip ["Traversal.FileModule"]
  defp photo_progress(:photo, entry, socket) do
    case consume_uploaded_entry(socket, entry, &{:ok, Photos.store(File.read!(&1.path))}) do
      {:ok, path} ->
        params = Map.put(socket.assigns.form.params, "photo", path)
        {:noreply, socket |> assign(:photo_upload_error, nil) |> assign_form(params, :validate)}

      {:error, reason} ->
        {:noreply, assign(socket, :photo_upload_error, photo_error(reason))}
    end
  end

  defp photo_error(:not_an_image), do: gettext("Choose a JPEG, PNG or WebP image.")

  defp photo_error(:too_large),
    do: gettext("The photo has too many pixels (at most 40 megapixels).")

  defp photo_error(:full),
    do: gettext("The demo has enough uploaded photos for today. Use a photo URL instead.")

  defp photo_error(:unreadable), do: gettext("The photo couldn't be read as an image.")

  defp track_editing(socket, product) do
    if connected?(socket) do
      topic = Presence.editing_topic(product.id)
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, topic)
      Phoenix.PubSub.subscribe(ClothingStore.PubSub, "products")
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
    # a form that only had its photo uploaded has no tags yet: they stay as they are
    params = Map.replace_lazy(params, "tags", &Products.parse_tags/1)

    changeset =
      socket.assigns.product
      |> Products.change_product(params)
      |> Map.put(:action, action)

    assign(socket, :form, to_form(changeset))
  end

  defp field_label("title"), do: gettext("Title")
  defp field_label("category"), do: gettext("Category")
  defp field_label("price"), do: gettext("Price")
  defp field_label("stock"), do: gettext("Stock")
  defp field_label("tags"), do: gettext("Tags")
  defp field_label("description"), do: gettext("Description")
  defp field_label("photo"), do: gettext("Photo")
  defp field_label(_discount), do: gettext("Discount")
end
