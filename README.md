# BioRadio

Free English-speaking live radio from 14 countries, as a single installable web page (PWA).

## Run it

It's a static site, so there's no build step.

- **GitHub Pages:** Settings → Pages → Deploy from branch → `main` / root. The site is served at `https://<user>.github.io/BioRadio/`.
- **Locally:** serve the folder with any static server (for example `npx serve .` or `python -m http.server`) and open `http://localhost:<port>/`. Opening `index.html` straight from disk works too, but the service worker / install prompt only work over http(s).

## Files

| File | What it is |
|---|---|
| `index.html` | The whole app: station list, search, player |
| `manifest.json` | PWA manifest (name, colours, icons) |
| `sw.js` | Service worker: caches the page so it opens on bad networks. Streams are never cached |
| `bioradio-logo.png` / `.svg` | App icon |

## Adding or fixing a station

Each station is a `.station-card` in `index.html`:

```html
<div class="station-card" data-url="https://stream-url" data-name="Station Name" data-country="Kenya">
```

Station and country counts are calculated automatically. `.m3u8` (HLS) streams work everywhere: Safari, iOS and Android play them natively, and other browsers load [hls.js](https://github.com/video-dev/hls.js) on demand.
Good places to find current stream URLs are [radio-browser.info](https://www.radio-browser.info/) and the station's own web player.
