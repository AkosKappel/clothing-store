// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#dc2626"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Mobile menu toggle. Delegated from document so it keeps working after LiveView
// navigation replaces the header; inline scripts would be blocked by the CSP.
document.addEventListener("click", event => {
  const toggle = event.target.closest("#menu-toggle")
  if (!toggle) return

  const open = document.getElementById("menu")?.classList.toggle("hidden") === false
  toggle.setAttribute("aria-expanded", open)
})

// Escape closes the open mobile menu and puts focus back on its button
document.addEventListener("keydown", event => {
  const menu = document.getElementById("menu")
  const toggle = document.getElementById("menu-toggle")
  if (event.key !== "Escape" || !menu || menu.classList.contains("hidden") || !toggle?.offsetParent) return

  menu.classList.add("hidden")
  toggle.setAttribute("aria-expanded", "false")
  toggle.focus()
})

// Pending state for regular (non-LiveView) forms: reuse LiveView's
// phx-submit-loading class so buttons show the same spinner, and ignore
// repeated submits while the request is in flight.
document.addEventListener("submit", event => {
  const form = event.target
  if (form.hasAttribute("phx-submit") || form.method === "dialog") return

  if (form.classList.contains("phx-submit-loading")) {
    event.preventDefault()
  } else {
    form.classList.add("phx-submit-loading")
  }
})

// Welcome dialog (Layouts.welcome_dialog/1): the server renders it with
// data-open-on-load until it has been shown once. The cookie is set on opening,
// because "Try the demo" leaves the page without closing the dialog.
const welcome = document.getElementById("welcome")
if (welcome?.hasAttribute("data-open-on-load")) {
  const secure = location.protocol === "https:" ? "; Secure" : ""
  document.cookie = `welcome_seen=1; Max-Age=31536000; Path=/; SameSite=Lax${secure}`
  welcome.showModal()
}

// Selects marked data-autosubmit (the inventory sort) apply on change
document.addEventListener("change", event => {
  if (event.target.matches("[data-autosubmit]")) event.target.form?.requestSubmit()
})

// Stepper buttons next to number inputs (the product stock): step the input, then
// let LiveView validate as if the visitor had typed it.
document.addEventListener("click", event => {
  const button = event.target.closest("[data-step-target]")
  const input = button && document.getElementById(button.dataset.stepTarget)
  if (!input) return

  Number(button.dataset.step) > 0 ? input.stepUp() : input.stepDown()
  input.dispatchEvent(new Event("input", {bubbles: true}))
})

// Enter in the tags input finishes a tag (it becomes a chip) instead of submitting the form
document.addEventListener("keydown", event => {
  const input = event.target
  if (event.key !== "Enter" || !input.matches?.("[data-tag-input]")) return

  event.preventDefault()
  if (input.value.trim() !== "" && !input.value.trim().endsWith(",")) input.value = input.value.trim() + ", "
  input.dispatchEvent(new Event("input", {bubbles: true}))
})

// Buttons marked data-print open the print dialog (the statistics report)
document.addEventListener("click", event => {
  if (event.target.closest("[data-print]")) window.print()
})

// Command palette (Layouts.command_palette/1): Ctrl+K or Cmd+K opens it, typing
// filters the pages, the last entry searches the inventory for what was typed.
const palette = document.getElementById("command-palette")
if (palette) {
  const input = palette.querySelector("#command-palette-input")
  const search = palette.querySelector("[data-palette-search]")
  // the options are the links; hiding filters their list items
  const visible = () => [...palette.querySelectorAll("[role=option]")].filter(option => !option.parentElement.hidden)

  const select = item => {
    palette.querySelectorAll("[role=option]").forEach(option => option.setAttribute("aria-selected", "false"))
    item?.setAttribute("aria-selected", "true")
    item ? input.setAttribute("aria-activedescendant", item.id) : input.removeAttribute("aria-activedescendant")
    item?.scrollIntoView({block: "nearest"})
  }

  const filter = () => {
    const query = input.value.trim()
    palette.querySelectorAll("[data-palette-item]").forEach(item => {
      item.hidden = !item.dataset.paletteItem.includes(query.toLowerCase())
    })
    search.hidden = query === ""
    search.querySelector("[data-palette-query]").textContent = query
    search.querySelector("[role=option]").href = `/products?q=${encodeURIComponent(query)}`
    select(visible()[0])
  }

  input.addEventListener("input", filter)
  input.addEventListener("keydown", event => {
    const items = visible()
    const current = items.findIndex(option => option.getAttribute("aria-selected") === "true")
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      select(items[(current + step + items.length) % items.length])
    } else if (event.key === "Enter" && items[current]) {
      event.preventDefault()
      items[current].click()
    }
  })

  document.addEventListener("keydown", event => {
    if (event.key.toLowerCase() !== "k" || !(event.ctrlKey || event.metaKey)) return
    event.preventDefault()
    if (palette.open) return palette.close()
    input.value = ""
    filter()
    palette.showModal()
  })
}

// Single-key shortcuts: an element with data-shortcut="n" is clicked (links) or
// focused (inputs) when that key is pressed outside a text field.
document.addEventListener("keydown", event => {
  if (event.ctrlKey || event.metaKey || event.altKey || event.isComposing) return
  if (event.target.closest("input, textarea, select, [contenteditable], dialog[open]")) return

  const target = [...document.querySelectorAll("[data-shortcut]")]
    .find(el => el.dataset.shortcut === event.key.toLowerCase())
  if (!target) return

  event.preventDefault()
  target.matches("input, textarea, select") ? target.focus() : target.click()
})

// Back/forward restores pages from the cache with the pending state still on.
window.addEventListener("pageshow", event => {
  if (event.persisted) {
    document.querySelectorAll("form.phx-submit-loading").forEach(form => {
      form.classList.remove("phx-submit-loading")
    })
  }
})

// <button commandfor command="show-modal"> opens dialogs natively; this covers
// browsers without invoker command support.
if (!("commandForElement" in HTMLButtonElement.prototype)) {
  document.addEventListener("click", event => {
    const button = event.target.closest("button[commandfor]")
    const dialog = button && document.getElementById(button.getAttribute("commandfor"))
    if (!(dialog instanceof HTMLDialogElement)) return

    if (button.getAttribute("command") === "show-modal") dialog.showModal()
    if (button.getAttribute("command") === "close") dialog.close()
  })
}

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

