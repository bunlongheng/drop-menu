# drop-menu — agent quick-orientation

You just pulled this repo. Read this first.

## What this is

A tiny, reusable menu UI for [Drop](https://github.com/bunlongheng/drop). Two pieces:

- **`web/index.html`** — single-file vanilla HTML+JS (~180 lines). Iframeable anywhere. Reads `?api=` to know which Drop server to call.
- **`native/DropMenu.swift`** — macOS menu bar binary (~95 lines). Loads `web/index.html` in a WKWebView popover. Reads `DROP_URL` env var.

The web page is the reusable widget. The Swift app is a thin wrapper.

## Hard constraints — do not violate

- **No frameworks in `web/`.** Vanilla HTML/CSS/JS only — no React, no Vue, no bundler, no npm. The whole appeal is a single static file.
- **No npm/package.json in this repo.** Keep it dependency-free.
- **`web/index.html` must stay iframeable.** Don't add `top.location =`, frame-busting, cookies, or anything that breaks cross-origin embedding.
- **Keep both pieces small.** Web < 250 lines, Swift < 150 lines. If a feature needs more, push back or split it out.
- **Read-only.** The menu lists drops; it does NOT upload, delete, or modify. Don't add write operations.
- **Don't touch the `drop` repo from here.** API changes live in `/Users/bheng/Sites/drop`. This repo is a pure consumer.

## How to run / test

```bash
# Web (standalone) — open in browser at http://localhost:4445/?api=http://localhost:4321
cd web && python3 -m http.server 4445

# Native — build then run
cd native && ./build.sh && DROP_URL=http://10.0.0.218:4321 ./DropMenu &
```

## Architecture decisions worth knowing

| Decision | Reason |
|---|---|
| `?api=` query param, not hardcoded | Same iframe works against any Drop instance (local, prod, other LAN) |
| `postMessage({type:"drop:open"|"drop:mouseleft"})` | Parent owns navigation + hide-on-leave; widget stays dumb |
| `file://` load in Swift WKWebView | No HTTP server needed for native; web/index.html ships next to the binary |
| WS with 4s polling fallback | WS fails on some networks; polling keeps it working |
| Lazy content fetch via IntersectionObserver | Grid loads instantly with metadata; thumbnails stream in as you scroll |

## Common changes — quick recipe

- **Change tile size / column count** → `.grid` CSS in `web/index.html` (currently `repeat(4, 1fr)`)
- **Change popover size** → `WKWebView` frame + `popover.contentSize` in `DropMenu.swift`
- **Change default API URL** → both `web/index.html` (`API = ...`) and `DropMenu.swift` (`dropURL`)
- **Add a new postMessage event** → emit in `web/index.html`, document in `README.md` event table

## Don't

- Don't add Electron, Tauri, Node, npm, bundlers, transpilers.
- Don't add auth, headers, or anything that assumes a specific Drop deployment.
- Don't add write actions (upload/delete) — that's what the main Drop UI is for.
- Don't import dependencies in `web/`. If you need PDF rendering or similar, add a CDN `<script>` only after asking.
- Don't break iframe embedding — test by serving from one port and pointing `?api=` at another.

## Commit style

Match the parent `drop` repo: short imperative subject, optional body. No Co-Authored-By lines. Push to `main` after each logical change.

## Memory references (parent project)

- See parent repo memory: `drop-menu-sibling-repo`, `drop-api-cors` — explain why this repo exists and why CORS is open on the Drop API.
