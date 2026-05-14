# drop-menu

A tiny, reusable menu UI for [Drop](https://github.com/bunlongheng/drop). Two pieces, both lean:

- **`web/index.html`** — vanilla HTML+JS (~180 lines), iframeable anywhere.
- **`native/DropMenu.swift`** — macOS menu bar shell (~95 lines) that loads the web page in a WKWebView popover.

The web page is the reusable part. The Swift app is just a thin wrapper that gives you a menu bar entry point.

```
┌──────────────────────┐
│  parent app / Swift  │
│  ┌────────────────┐  │
│  │ web/index.html │──┼──► GET /api/drop ──► your Drop server
│  │   (iframe)     │  │
│  └────────────────┘  │
└──────────────────────┘
```

---

## Web — iframe embed

Serve `web/index.html` from any static host (Vercel, Netlify, S3, `python3 -m http.server`, etc.), then embed it:

```html
<iframe src="https://your-host.example.com/?api=http://10.0.0.218:4321"
        width="360" height="480" frameborder="0"></iframe>
```

### Query params

| Param | Default | Description |
|---|---|---|
| `api` | `http://10.0.0.218:4321` | Drop server base URL (no trailing slash) |
| `channel` | `default` | Channel name to display |

### postMessage events

The iframe emits these events on `window.parent`:

| Event | Payload | When |
|---|---|---|
| `drop:open` | `{ type, id, api }` | User clicked a tile — open the full Drop UI or do whatever you want |
| `drop:mouseleft` | `{ type }` | Mouse left the iframe — parent can hide/close the menu |

```js
window.addEventListener("message", e => {
  if (e.data.type === "drop:open") {
    window.open(`${e.data.api}/?focus=${e.data.id}`, "_blank");
  } else if (e.data.type === "drop:mouseleft") {
    closeMyMenu();
  }
});
```

### Live updates

The web page connects to `${api}/ws?channel=${channel}` for WebSocket push, and falls back to polling every 4s if WS fails. New drops appear without a refresh.

---

## Native — macOS menu bar

```bash
cd native
./build.sh
DROP_URL=http://10.0.0.218:4321 ./DropMenu &
```

### What it does

- Sits in the menu bar with a system `arrow.down.to.line` icon (template — adapts to light/dark)
- Click to open a 360×480 popover with the menu grid
- Mouse leaves the popover area → auto-hides
- No Dock icon (`activationPolicy = .accessory`)
- WKWebView loads `web/index.html` via `file://` and passes `DROP_URL` as `?api=`

### Configuration

| Env var | Default | Description |
|---|---|---|
| `DROP_URL` | `http://10.0.0.218:4321` | Drop server base URL |

### Requirements

- macOS 13+
- Xcode Command Line Tools: `xcode-select --install`
- A running Drop server (local or remote)

### Build output

`./build.sh` produces a single binary `native/DropMenu` next to the source. No bundle, no signing required for personal use.

---

## CORS requirement

The Drop server must send permissive CORS headers on `/api/drop` so the menu (loading from another origin or `file://`) can fetch data. The upstream `drop` repo handles this in `next.config.ts`:

```ts
async headers() {
  return [{
    source: "/api/drop/:path*",
    headers: [
      { key: "Access-Control-Allow-Origin", value: "*" },
      { key: "Access-Control-Allow-Methods", value: "GET,POST,DELETE,OPTIONS" },
      { key: "Access-Control-Allow-Headers", value: "Content-Type" },
    ],
  }];
}
```

If the menu shows "Cannot reach …", check the Drop server has those headers.

---

## Drop API used

The menu only reads — it never writes. Two endpoints:

| Method | Endpoint | Used for |
|---|---|---|
| `GET` | `/api/drop?channel=default` | List items (no content, just metadata) |
| `GET` | `/api/drop?id=<uuid>` | Fetch full content for one item (lazy, on scroll) |
| `WS` | `/ws?channel=default` | Live push when a new drop arrives |

See [`DROPZONE_API.md`](https://github.com/bunlongheng/drop/blob/main/DROPZONE_API.md) in the parent Drop repo for full API details.

---

## Repo layout

```
drop-menu/
├── .gitignore
├── README.md
├── web/
│   └── index.html       # iframeable menu page
└── native/
    ├── build.sh         # compiles DropMenu binary
    ├── DropMenu.swift   # menu bar app source
    └── DropMenu         # built binary (gitignored)
```

---

## Why this exists

The main Drop app is the full UI — drag-drop, paste, search, delete, modal, history. The menu is the *opposite*: a tiny read-only window into the same data, designed to live in places where the full UI is too heavy (menu bar, sidebar widget, embedded panel in another product).

Keeping it separate from the main `drop` repo so:

1. The full Drop app can change freely without coupling the embeddable widget.
2. Other products can iframe this without pulling in Next.js/Tailwind/React.
3. The Swift wrapper stays under 100 lines.
