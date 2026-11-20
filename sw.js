// BioRadio service worker
// - App shell: network first (so updates show), cache fallback (so it opens on bad / no network)
// - Station logos: cache first (they rarely change; saves data on 2G/3G)
// - Audio streams and other sites: never touched
const CACHE = 'bioradio-v3';
const LOGO_CACHE = 'bioradio-logos-v1';
const SHELL = ['./', './index.html', './manifest.json', './bioradio-logo.png', './bioradio-logo-192.png', './bioradio-logo.svg'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE && k !== LOGO_CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;

  if (url.pathname.includes('/logos/')) {
    event.respondWith(
      caches.open(LOGO_CACHE).then(cache =>
        cache.match(req).then(hit => hit || fetch(req).then(res => {
          if (res.ok) cache.put(req, res.clone());
          return res;
        }))
      )
    );
    return;
  }

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
