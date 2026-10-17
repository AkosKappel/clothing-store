// Service worker: makes the dashboard installable and shows an offline page when
// a page can't load. Everything else goes straight to the network, because the
// data is live; nothing but the offline page and its logo is cached.
const CACHE = "offline-v1"
const OFFLINE = ["/offline.html", "/images/logo.svg"]

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(OFFLINE)))
  self.skipWaiting()
})

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", event => {
  const {request} = event
  if (request.mode === "navigate") {
    event.respondWith(fetch(request).catch(() => caches.match("/offline.html")))
  } else if (OFFLINE.includes(new URL(request.url).pathname)) {
    event.respondWith(caches.match(request).then(cached => cached || fetch(request)))
  }
})
