defmodule ClothingStoreWeb.PageHTML do
  import ClothingStoreWeb.Helpers, only: [format_price: 1, format_date: 1]

  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ClothingStoreWeb, :html

  embed_templates "page_html/*"
end
