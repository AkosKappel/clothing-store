defmodule ClothingStoreWeb.PageController do
  use ClothingStoreWeb, :controller

  alias ClothingStore.{About, Demo, Products, Transactions}
  alias ClothingStoreWeb.{CSV, Helpers}

  def about(conn, _params) do
    links = Demo.links()

    render(conn, :about,
      page_title: gettext("About"),
      author: Demo.author(),
      links: links,
      repository: links[:repository],
      reset: Demo.reset_settings(),
      photo_sources: About.photo_sources(),
      stack: About.stack()
    )
  end

  def privacy(conn, _params) do
    render(conn, :privacy, page_title: gettext("Privacy"), reset: Demo.reset_settings())
  end

  def terms(conn, _params) do
    render(conn, :terms,
      page_title: gettext("Terms of use"),
      reset: Demo.reset_settings(),
      repository: Demo.links()[:repository],
      max_products: Products.max_products()
    )
  end

  @doc "One row per line item of the month's transactions (or all of them), as CSV."
  def transactions_csv(conn, params) do
    {selected_month, month} = Helpers.parse_month(params["month"])

    rows =
      for t <- Transactions.list_transactions(month), item <- t.products_transactions do
        [
          t.id,
          t.inserted_at,
          item.product_id,
          item.product.title,
          item.quantity,
          item.unit_price,
          Decimal.mult(item.unit_price, item.quantity)
        ]
      end

    header = ~w(transaction_id date product_id product quantity unit_price line_total)

    send_download(conn, {:binary, CSV.encode([header | rows])},
      filename: "transactions-#{selected_month || "all"}.csv",
      content_type: "text/csv"
    )
  end
end
