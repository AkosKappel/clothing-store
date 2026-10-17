defmodule ClothingStoreWeb.ProductLive.Import do
  @moduledoc """
  Inventory import from a CSV file in the export's format. Small files only
  (100 KB, `Products.max_import_rows/0` rows); every row is checked before
  anything is saved.
  """
  use ClothingStoreWeb, :live_view

  alias ClothingStore.Products
  alias ClothingStoreWeb.CSV

  @max_bytes 100_000
  @columns ~w(id title category tags price stock description photo)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.back navigate={~p"/products"}>Inventory</.back>
      <.header>
        Import products
        <:subtitle>
          Add or update products from a CSV file, for example an edited inventory export.
        </:subtitle>
      </.header>

      <div class="card space-y-5 p-6 sm:p-8">
        <div class="space-y-2 text-sm text-gray-700">
          <p>
            The first line names the columns: <code class="text-xs">{Enum.join(@columns, ", ")}</code>. A row with the id of an existing product updates the columns it has; every other row adds a product (without a description or photo it gets a placeholder).
          </p>
          <p>
            At most {Products.max_import_rows()} rows and {div(@max_bytes, 1000)} KB. If any row is invalid, nothing is imported.
          </p>
        </div>

        <form id="import-form" phx-submit="import" phx-change="validate" class="space-y-4">
          <div>
            <label for={@uploads.csv.ref} class="block text-sm font-semibold text-gray-800">
              CSV file
            </label>
            <.live_file_input
              upload={@uploads.csv}
              class="mt-1.5 block w-full text-sm text-gray-700 file:mr-3 file:rounded-md file:border-0 file:bg-gray-100 file:px-3 file:py-2 file:font-semibold file:text-gray-800 hover:file:bg-gray-200"
            />
            <p
              :for={entry <- @uploads.csv.entries}
              :if={entry.valid?}
              class="mt-2 text-sm text-gray-600"
            >
              {entry.client_name} ({Float.round(entry.client_size / 1000, 1)} KB)
            </p>
            <.error :for={error <- upload_errors(@uploads.csv) ++ entry_errors(@uploads.csv)}>
              {error_text(error)}
            </.error>
          </div>
          <div class="flex justify-end gap-3 border-t border-gray-100 pt-4">
            <.button navigate={~p"/products"} variant="secondary">Cancel</.button>
            <.button
              type="submit"
              icon="hero-arrow-up-tray"
              disabled={@uploads.csv.entries == []}
              phx-disable-with="Importing..."
            >
              Import
            </.button>
          </div>
        </form>

        <div
          :if={match?({:ok, _}, @result)}
          id="import-result"
          role="status"
          class="flex gap-3 rounded-md bg-emerald-50 p-4 text-sm text-emerald-900 ring-1 ring-emerald-600/20"
        >
          <.icon name="hero-check-circle-mini" class="size-5 shrink-0 text-emerald-600" />
          <p>
            Imported: {elem(@result, 1).created} added, {elem(@result, 1).updated} updated.
            <.link navigate={~p"/products"} class="font-semibold underline">Open the inventory</.link>
          </p>
        </div>

        <div
          :if={match?({:error, _}, @result)}
          id="import-errors"
          role="alert"
          class="rounded-md bg-rose-50 p-4 text-sm text-rose-900 ring-1 ring-rose-600/20"
        >
          <p class="font-semibold">Nothing was imported. Please fix these rows:</p>
          <ul class="mt-2 list-disc space-y-1 pl-5">
            <li :for={{line, message} <- Enum.take(elem(@result, 1), 20)}>
              {if line > 1, do: "Line #{line}: ", else: ""}{message}
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Import products",
       columns: @columns,
       max_bytes: @max_bytes,
       result: nil
     )
     |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1, max_file_size: @max_bytes)}
  end

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, assign(socket, :result, nil)}

  def handle_event("import", _params, socket) do
    files = consume_uploaded_entries(socket, :csv, &read_upload/2)

    result =
      case files do
        [csv] -> import_csv(csv)
        [] -> {:error, [{1, "Choose a CSV file first"}]}
      end

    {:noreply, assign(socket, :result, result)}
  end

  # the upload's temporary file, written by LiveView itself
  # sobelow_skip ["Traversal.FileModule"]
  defp read_upload(%{path: path}, _entry), do: {:ok, File.read!(path)}

  @doc "Parses an import file and hands its rows to `Products.import_products/1`."
  def import_csv(csv) do
    with {:ok, [header | rows]} <- CSV.decode(csv),
         header = Enum.map(header, &(&1 |> String.trim() |> String.downcase())),
         true <- Enum.any?(header, &(&1 in ["id", "title"])) || :no_columns do
      rows
      |> Enum.map(fn row -> header |> Enum.zip(Enum.map(row, &CSV.unguard/1)) |> Map.new() end)
      |> Products.import_products()
    else
      :no_columns ->
        {:error, [{1, "The first line must name the columns, including id or title"}]}

      _ ->
        {:error, [{1, "This isn't a readable CSV file"}]}
    end
  end

  defp entry_errors(upload), do: Enum.flat_map(upload.entries, &upload_errors(upload, &1))

  defp error_text(:too_large), do: "The file is larger than #{div(@max_bytes, 1000)} KB"
  defp error_text(:not_accepted), do: "Choose a .csv file"
  defp error_text(:too_many_files), do: "Choose one file"
  defp error_text(_error), do: "The file can't be uploaded"
end
