import Foundation

@MainActor
final class AppState: ObservableObject {
    let rules = RuleStore()
    let counter = BlockCounter()
    let watcher: BrowserWatcher

    @Published private(set) var isEnabled: Bool
    /// Called after a tab is blocked (used for the icon animation).
    var onBlocked: (() -> Void)?

    private static let enabledKey = "enabled"
    private let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true

        let rules = rules
        let counter = counter
        watcher = BrowserWatcher(
            matcher: { rules.matcher },
            blockURL: { BlockPage.url(blockedURL: $0, count: counter.today) }
        )
        watcher.onBlock = { [weak self] _, _ in
            counter.increment()
            self?.onBlocked?()
        }

        // Unit tests load the app as a host; do not touch browsers there.
        if isEnabled && !isTesting { watcher.start() }
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
        if enabled && !isTesting { watcher.start() } else { watcher.stop() }
    }
}
