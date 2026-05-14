# drop-menu

A tiny, reusable menu UI for [Drop](https://github.com/bunlongheng/drop).

Two pieces, both lean:

- `web/index.html` - vanilla HTML+JS, ~180 lines, iframeable anywhere
- `native/DropMenu.swift` - ~100 lines, macOS menu bar shell that loads `web/index.html` in a WKWebView popover

The web page is the reusable part. The Swift app is just a thin wrapper that gives you a menu bar entry point.

---

## Web (iframe)

```html
<iframe src="https://drop-menu.example.com/?api=http://10.0.0.218:4321"
        width="360" height="480" frameborder="0"></iframe>
```

Query params:

| Param | Default | Description |
|---|---|---|
| `api` | `http://10.0.0.218:4321` | Drop server base URL |
| `channel` | `default` | Channel to display |

Iframe events (postMessage):

- `{ type: "drop:open", id, api }` - user clicked a tile
- `{ type: "drop:mouseleft" }` - mouse left the iframe (parent can hide menu)

---

## Native (macOS menu bar)

```bash
cd native
./build.sh
DROP_URL=http://10.0.0.218:4321 ./DropMenu &
```

The Swift app loads `web/index.html` via `file://` and passes `DROP_URL` as the `?api=` param.

Requirements: macOS 13+, `xcode-select --install`.
