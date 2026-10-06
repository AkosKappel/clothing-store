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

