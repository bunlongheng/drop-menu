import AppKit
import WebKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var webView: WKWebView!
    var mouseTracker: Any?

    var dropURL: String {
        ProcessInfo.processInfo.environment["DROP_URL"] ?? "http://10.0.0.218:4321"
    }

    var menuURL: URL {
        let bundlePath = Bundle.main.bundlePath
        let exeDir = (bundlePath as NSString).deletingLastPathComponent
        let candidates = [
            (exeDir as NSString).appendingPathComponent("../web/index.html"),
            (exeDir as NSString).appendingPathComponent("web/index.html"),
            Bundle.main.path(forResource: "index", ofType: "html") ?? ""
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            let encoded = dropURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? dropURL
            return URL(fileURLWithPath: path).appendingQueryItem("api", value: encoded)
        }
        return URL(string: "\(dropURL)?api=\(dropURL)")!
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        setupStatusBar()
        setupPopover()
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let btn = statusItem.button else { return }
        btn.image = NSImage(systemSymbolName: "arrow.down.to.line", accessibilityDescription: "Drop")
        btn.image?.isTemplate = true
        btn.action = #selector(togglePopover(_:))
        btn.target = self
    }

    func setupPopover() {
        let cfg = WKWebViewConfiguration()
        cfg.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 360, height: 480), configuration: cfg)
        webView.loadFileURL(menuURL, allowingReadAccessTo: menuURL.deletingLastPathComponent())

        let vc = NSViewController()
        vc.view = webView
        vc.view.wantsLayer = true
        vc.view.layer?.backgroundColor = NSColor(red: 0.008, green: 0.008, blue: 0.012, alpha: 1).cgColor

        popover = NSPopover()
        popover.contentViewController = vc
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let btn = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
            stopMouseTracking()
        } else {
            webView.reload()
            popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY)
            startMouseTracking()
        }
    }

    func startMouseTracking() {
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self, self.popover.isShown,
                  let window = self.popover.contentViewController?.view.window else { return }
            let frame = window.frame.insetBy(dx: -16, dy: -16)
            if !frame.contains(NSEvent.mouseLocation) {
                self.popover.performClose(nil)
                self.stopMouseTracking()
            }
        }
    }

    func stopMouseTracking() {
        if let t = mouseTracker { NSEvent.removeMonitor(t); mouseTracker = nil }
    }
}

extension URL {
    func appendingQueryItem(_ name: String, value: String) -> URL {
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) ?? URLComponents()
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: name, value: value))
        comps.queryItems = items
        return comps.url ?? self
    }
}
