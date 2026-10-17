defmodule ClothingStoreWeb.SalesComponents do
  @moduledoc "Helpers and components for the transactions and statistics pages."
  use ClothingStoreWeb, :html

  import ClothingStoreWeb.Helpers

  @doc ~S'~D[2026-10-01] -> "2026-10", the month filter value'
  def month_param(%Date{} = month), do: Calendar.strftime(month, "%Y-%m")

  @doc "The month (its first day) of a group of transactions from the same month."
  def month_of([transaction | _]),
    do: transaction.inserted_at |> DateTime.to_date() |> Date.beginning_of_month()

  @doc "Query params for a page of the transactions list, keeping the month filter."
  def page_params(nil, page), do: [page: page]
  def page_params(month, page), do: [month: month, page: page]

  @doc "A euro amount rounded for chart axes: 850 €, 1.5k €, 12k €."
  def short_euro(value) do
    value = to_float(value)

    if value >= 1000 do
      thousands = Float.round(value / 1000, 1)
      text = if thousands == trunc(thousands), do: trunc(thousands), else: thousands
      "#{text}k €"
    else
      "#{round(value)} €"
    end
  end

  @doc "Revenue per month as bars for `ChartComponents.bar_chart/1`."
  def revenue_bars(monthly) do
    for %{month: month, revenue: revenue, count: count} <- monthly do
      %{
        label: strftime(month, "%b"),
        value: to_float(revenue),
        tooltip:
          gettext("%{month}: %{revenue} from %{sales}",
            month: strftime(month, "%B %Y"),
            revenue: format_price(revenue),
            sales: ngettext("1 sale", "%{count} sales", count)
          )
      }
    end
  end

  @doc """
  Category revenue as donut segments: the six largest, the rest folded into
  "Other" so no colour has to be invented.
  """
  def category_segments(categories) do
    {top, rest} = Enum.split(categories, 6)

    segments =
      for {category, revenue} <- top do
        %{
          label: category,
          value: to_float(revenue),
          color: category_color(category),
          text: format_price(revenue)
        }
      end

    case rest do
      [] ->
        segments

      rest ->
        revenue = rest |> Enum.map(&elem(&1, 1)) |> Enum.reduce(&Decimal.add/2)

        segments ++
          [
            %{
              label: gettext("Other"),
              value: to_float(revenue),
              color: other_color(),
              text: format_price(revenue)
            }
          ]
    end
  end

  def sum_revenue(categories),
    do: categories |> Enum.map(&elem(&1, 1)) |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

  defp to_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp to_float(value), do: value / 1

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
        <:col :let={{{product, _sold}, rank}} label={gettext("Product")}>
          <span class="mr-2 inline-block w-5 font-semibold text-gray-500">{rank}.</span>
          <.link
            navigate={~p"/products/#{product}"}
            class="font-medium text-gray-900 hover:text-red-700 hover:underline"
          >
            {product.title}
          </.link>
        </:col>
        <:col
          :let={{{product, _sold}, _rank}}
          label={gettext("Price")}
          class="text-right whitespace-nowrap"
        >
          {format_price(product.price)}
        </:col>
        <:col
          :let={{{_product, sold}, _rank}}
          label={gettext("Sold")}
          class="text-right whitespace-nowrap"
        >
          {sold}
        </:col>
        <:col
          :let={{{product, _sold}, _rank}}
          label={gettext("In stock")}
          class="text-right whitespace-nowrap"
        >
          <.stock_badge stock={product.stock} />
        </:col>
        <:empty>
          <.empty_state icon="hero-chart-bar" title={@empty} class="py-8" />
        </:empty>
      </.table>
    </section>
    """
  end
end
