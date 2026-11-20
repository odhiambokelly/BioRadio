# BioRadio

Free English-speaking live radio from around the world, as one fast, installable web app (PWA).
Built to work on 2G, 3G and 4G.

## Run it

It's a static site, so there's no build step.

- **GitHub Pages:** Settings → Pages → Deploy from branch → `main` / root. The site is served at `https://<user>.github.io/BioRadio/`.
- **Locally:** serve the folder with any static server (for example `npx serve .` or `python -m http.server`) and open `http://localhost:<port>/`.

## Download / install the app

The **⬇ Download App** button installs BioRadio like a normal app:

- **Android (Chrome, Edge, Samsung Internet):** tap *Download App* → *Install*. It shows on the home screen and in the app drawer.
- **PC (Chrome or Edge on Windows, Mac, Linux):** click *Download App* → *Install*. It gets its own window, Start-menu / Dock entry and desktop shortcut.
- **iPhone / iPad:** Safari → Share → *Add to Home Screen* (the button shows these steps).

## Made for slow networks

- One small HTML file (no web fonts, no frameworks). Station logos are tiny 96×96 WebP files that load only when scrolled into view and are cached for offline use.
- **Data saver** switch (turns on automatically on 2G / "Save data"): uses 48 kbps versions of the BBC streams and low-bitrate versions of iono.fm (South African) streams.
- HLS (`.m3u8`) streams adapt their quality to the connection. Browsers without built-in HLS load [hls.js](https://github.com/video-dev/hls.js) only when needed.
- Up to 10 automatic retries on weak connections, and quick skipping of stations that are offline.

## Files

| File | What it is |
|---|---|
| `index.html` | The whole app: station data (in the `stationData` script block), search, player |
| `logos/` | Station logos (96×96 WebP) |
| `manifest.json` | PWA manifest (name, colours, icons) |
| `sw.js` | Service worker: caches the page and logos. Streams are never cached |
| `bioradio-logo*.png` / `.svg` | App icons |

## Adding or fixing a station

Stations live in the JSON inside `<script id="stationData">` in `index.html`, grouped by country:

```json
{ "c": "Kenya", "cc": "KE", "s": [
  ["Station Name", "News, Talk", "95.6 FM", "https://stream-url", "ke-station-name.webp", "https://optional-low-bitrate-url"]
]}
```

Use `null` for a missing logo (a coloured initials badge is shown instead) or a missing low-bitrate URL.
Station and country counts, the menu and the flags are generated automatically.
[radio-browser.info](https://www.radio-browser.info/) and the station's own web player are good places to find current stream URLs.
