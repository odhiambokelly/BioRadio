// BioRadio service worker: caches the app shell so the page opens offline / on bad networks.
// Audio streams are never cached — they always go straight to the network.
const CACHE = 'bioradio-v2';
const SHELL = ['./', './index.html', './manifest.json', './bioradio-logo.png', './bioradio-logo.svg'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);
  // Only handle same-origin GETs; let streams, fonts and CDNs pass through untouched.
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;

  // Network first for the page so updates show up, cache as fallback.
  event.respondWith(
    fetch(req)
      .then(res => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      })
      .catch(() => caches.match(req).then(r => r || caches.match('./index.html')))
  );
});
