import AppKit

/// Polls running browsers, and sends any tab that matches a rule to the
/// block page.
@MainActor
final class BrowserWatcher: ObservableObject {
    enum Access: Equatable {
        case allowed
        case denied
        case error(String)
    }

    /// Last known Automation state per browser bundle ID.
    @Published private(set) var access: [String: Access] = [:]

    var interval: TimeInterval = 0.7
    /// Called on the main actor each time a tab is blocked.
    var onBlock: ((_ url: String, _ rule: Rule) -> Void)?

    private let runner = ScriptRunner()
    private var timer: Timer?
    private var tickInFlight = false
    private var matcherProvider: () -> Matcher
    private var blockURLProvider: (_ blockedURL: String) -> String

    /// The browser the user used most recently. Opening our menu does not
    /// activate FxxkScroll, but we track this to be safe.
    @Published private(set) var lastBrowser: Browser?

    init(matcher: @escaping () -> Matcher,
         blockURL: @escaping (_ blockedURL: String) -> String) {
        matcherProvider = matcher
        blockURLProvider = blockURL

        if let id = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            lastBrowser = Browser.with(bundleID: id)
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard let id = app?.bundleIdentifier, let browser = Browser.with(bundleID: id) else { return }
            MainActor.assumeIsolated { self?.lastBrowser = browser }
        }
    }

    /// URL of the visible tab in the front window of the last used browser.
    func currentTabURL(completion: @escaping @MainActor (String?) -> Void) {
        guard let browser = lastBrowser else { return completion(nil) }
        let runner = runner
        runner.queue.async {
            let url = try? runner.run(browser.frontTabScript).get().stringValue
            DispatchQueue.main.async {
                MainActor.assumeIsolated { completion(url) }
            }
        }
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.15
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !tickInFlight else { return }
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        let browsers = Browser.all.filter { running.contains($0.bundleID) }
        guard !browsers.isEmpty else { return }

        tickInFlight = true
        let matcher = matcherProvider()
        let runner = runner

        runner.queue.async { [weak self] in
            var updates: [String: Access] = [:]
            var hits: [(browser: Browser, windowID: Int, url: String, rule: Rule)] = []

            for browser in browsers {
                switch runner.run(browser.readTabsScript) {
                case .success(let list):
                    updates[browser.bundleID] = .allowed
                    for tab in Self.parseTabs(list) {
                        if let rule = matcher.firstMatch(for: tab.url) {
                            hits.append((browser, tab.windowID, tab.url, rule))
                        }
                    }
                case .failure(.notAuthorized):
                    updates[browser.bundleID] = .denied
                case .failure(.failed(let code, let message)):
                    // -600: app quit between the check and the call. Not worth showing.
                    if code != -600 { updates[browser.bundleID] = .error("\(code) \(message)") }
                }
            }

            let finalHits = hits
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.access.merge(updates) { _, new in new }
                    self.tickInFlight = false
                    for hit in finalHits {
                        self.redirect(hit.browser, windowID: hit.windowID, url: hit.url, rule: hit.rule)
                    }
                }
            }
        }
    }

    private func redirect(_ browser: Browser, windowID: Int, url: String, rule: Rule) {
        // Count first so the block page shows the new total.
        onBlock?(url, rule)
        let script = browser.redirectScript(windowID: windowID, to: blockURLProvider(url))
        runner.queue.async { [runner] in
            _ = runner.run(script, cacheable: false)
        }
    }

    nonisolated private static func parseTabs(_ list: NSAppleEventDescriptor) -> [(windowID: Int, url: String)] {
        guard list.numberOfItems > 0 else { return [] }
        return (1...list.numberOfItems).compactMap { index in
            guard let pair = list.atIndex(index), pair.numberOfItems == 2,
                  let id = pair.atIndex(1)?.int32Value,
                  let url = pair.atIndex(2)?.stringValue
            else { return nil }
            return (Int(id), url)
        }
    }
}
