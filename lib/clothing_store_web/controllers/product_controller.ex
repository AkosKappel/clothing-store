defmodule ClothingStoreWeb.ProductController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.Products
  alias ClothingStoreWeb.{CSV, ProductHTML}

  @doc "The filtered inventory as CSV, in the inventory's sort order."
  def export(conn, params) do
    rows =
      for p <- Products.list_products(ProductHTML.filter_params(params)) do
        [p.id, p.title, p.category, Enum.join(p.tags, ", "), p.price, p.stock, p.updated_at]
      end

    send_download(
      conn,
      {:binary, CSV.encode([~w(id title category tags price stock updated_at) | rows])},
      filename: "inventory-#{Date.utc_today()}.csv",
      content_type: "text/csv"
    )
  end

  def create(conn, %{"product" => product_params}) do
    tags = Products.parse_tags(product_params["tags"])
    product_params = Map.put(product_params, "tags", tags)

    case Products.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, gettext("Product created successfully."))
        |> redirect(to: ~p"/products/#{product}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, page_title: gettext("New product"), changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Products.get_product!(id)

    tags = Products.parse_tags(product_params["tags"])
    product_params = Map.put(product_params, "tags", tags)

    case Products.update_product(product, product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, gettext("Product updated successfully."))
        |> redirect(to: ~p"/products/#{product}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          page_title: gettext("Edit product"),
          product: product,
          changeset: changeset
        )
    end
  end

  def restore(conn, %{"id" => id}) do
    case Products.restore_product(id) do
      {:ok, product} ->
        conn
        |> put_flash(:info, gettext("%{title} is back.", title: product.title))
        |> redirect(to: ~p"/products/#{product}")

      {:error, :catalogue_full} ->
        conn
        |> put_flash(:error, gettext("The catalogue is full, so the product can't come back."))
        |> redirect(to: ~p"/products")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, gettext("That product can't be restored any more."))
        |> redirect(to: ~p"/products")
    end
  end

  def revert(conn, %{"id" => id, "version_id" => version_id}) do
    product = Products.get_product!(id)

    case Products.revert_to_version(product, version_id) do
      {:ok, product} ->
        conn
        |> put_flash(
          :info,
          gettext("Restored the earlier details of %{title}.", title: product.title)
        )
        |> redirect(to: ~p"/products/#{product}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("That version can't be restored."))
        |> redirect(to: ~p"/products/#{product}")
    end
  end

  def label(conn, %{"id" => id}) do
    product = Products.get_product!(id)

    render(conn, :label,
      page_title: gettext("Label: %{title}", title: product.title),
      product: product
    )
  end

  def restock(conn, %{"id" => id}) do
    product = Products.get_product!(id)

    case Products.restock_product(product) do
      {:ok, product} ->
        conn
        |> put_flash(
          :info,
          gettext("Restocked: %{title} now has %{stock} in stock.",
            title: product.title,
            stock: product.stock
          )
        )
        |> redirect(to: ~p"/products/#{product}")

      {:error, :not_found} ->
        raise Ecto.NoResultsError, queryable: ClothingStore.Products.Product
    end
  end

  def delete(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    {:ok, _product} = Products.delete_product(product)

    conn
    |> put_flash(:info, gettext("%{title} was deleted.", title: product.title))
    |> put_flash(:undo, to_string(product.id))
    |> redirect(to: ~p"/products")
  end
end
