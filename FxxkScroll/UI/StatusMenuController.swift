import AppKit

/// Native status item and menu. AppKit instead of SwiftUI MenuBarExtra,
/// whose nested menus do not open reliably.
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let state: AppState
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    private var countdown: DisableCountdown?
    private var animationTimer: Timer?

    init(state: AppState) {
        self.state = state
        super.init()

        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu
        updateIcon()

        state.onBlocked = { [weak self] in self?.playBlockAnimation() }
    }

    // MARK: - Icon

    /// On: the finger flicks now and then (still if Reduce Motion is set).
    /// Off: a dimmed, still outline.
    private func updateIcon() {
        guard let button = statusItem.button else { return }
        button.appearsDisabled = !state.isEnabled
        if state.isEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            play(HandIcon.idle, loop: true)
        } else {
            stopAnimation()
            button.image = state.isEnabled ? HandIcon.on : HandIcon.off
        }
    }

    private func playBlockAnimation() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        play(HandIcon.block, loop: false)
    }

    private var frames: [HandIcon.Frame] = []
    private var frameIndex = 0
    private var looping = false

    private func play(_ frames: [HandIcon.Frame], loop: Bool) {
        stopAnimation()
        self.frames = frames
        frameIndex = 0
        looping = loop
        showNextFrame()
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func showNextFrame() {
        if frameIndex >= frames.count {
            guard looping else { updateIcon(); return }
            frameIndex = 0
        }
        let frame = frames[frameIndex]
        frameIndex += 1
        statusItem.button?.image = frame.image
        let timer = Timer(timeInterval: frame.duration, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.showNextFrame() }
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    // MARK: - Menu

    // Rebuilt every time the menu opens, so it always shows current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        state.counter.refresh()
        menu.removeAllItems()

        menu.addItem(label(state.isEnabled
            ? String(localized: "FxxkScroll is on")
            : String(localized: "FxxkScroll is off")))
        menu.addItem(label(String(localized: "Blocked \(state.counter.today) today")))

        let denied = deniedBrowserNames
        if state.isEnabled && !denied.isEmpty {
            menu.addItem(label(String(localized: "No permission: \(denied.joined(separator: ", "))")))
        }

        menu.addItem(.separator())

        menu.addItem(state.isEnabled
            ? item(String(localized: "Turn Off…"), #selector(turnOff))
            : item(String(localized: "Turn On"), #selector(turnOn)))

        menu.addItem(.separator())

        let rulesItem = NSMenuItem(title: String(localized: "Block List"), action: nil, keyEquivalent: "")
        rulesItem.submenu = rulesMenu()
        menu.addItem(rulesItem)

        menu.addItem(.separator())

        menu.addItem(item(String(localized: "View on GitHub"), #selector(openGitHub)))

        menu.addItem(.separator())

        menu.addItem(item(String(localized: "Quit"), #selector(quit), key: "q"))
    }

    private func rulesMenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        for rule in state.rules.rules {
            let ruleItem = item(rule.pattern, #selector(toggleRule(_:)))
            ruleItem.state = rule.isEnabled ? .on : .off
            ruleItem.representedObject = rule.id
            submenu.addItem(ruleItem)

            // Shown instead of the item above while ⌥ is held.
            let deleteItem = item(String(localized: "Delete \(rule.pattern)"), #selector(deleteRule(_:)))
            deleteItem.representedObject = rule.id
            deleteItem.keyEquivalentModifierMask = .option
            deleteItem.isAlternate = true
            submenu.addItem(deleteItem)
        }

        submenu.addItem(.separator())

        let addCurrent: NSMenuItem
        addCurrent = item(String(localized: "Add Current Tab"), #selector(addCurrentTab))
        addCurrent.isEnabled = state.watcher.lastBrowser != nil
        submenu.addItem(addCurrent)
        submenu.addItem(item(String(localized: "Add Manually…"), #selector(addPattern)))

        submenu.addItem(.separator())
        submenu.addItem(label(String(localized: "Hold ⌥ to delete")))
        return submenu
    }

    // MARK: - Actions

    @objc private func turnOff() {
        if countdown == nil {
            countdown = DisableCountdown { [weak self] in
                self?.state.setEnabled(false)
                self?.updateIcon()
            }
        }
        countdown?.show()
    }

    @objc private func turnOn() {
        state.setEnabled(true)
        updateIcon()
    }

    @objc private func toggleRule(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        state.rules.toggle(id: id)
    }

    @objc private func deleteRule(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        state.rules.remove(id: id)
    }

    @objc private func addCurrentTab() {
        state.watcher.currentTabURL { [weak self] url in
            guard let self else { return }
            guard let url, let suggestion = Matcher.suggestedPattern(for: url) else {
                self.showMessage(String(localized: "Could not read the tab."),
                                 detail: String(localized: "Open a page in your browser first."))
                return
            }
            self.promptForPattern(prefill: suggestion)
        }
    }

    @objc private func addPattern() {
        promptForPattern(prefill: "")
    }

    private func promptForPattern(prefill: String) {
        let alert = NSAlert()
        alert.messageText = String(localized: "Add to Block List")
        alert.informativeText = String(localized: "e.g. facebook.com/reel/*")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        field.stringValue = prefill
        field.placeholderString = "facebook.com/reel/*"
        alert.accessoryView = field
        alert.addButton(withTitle: String(localized: "Add"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.window.initialFirstResponder = field

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let pattern = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty else { return }
        guard Matcher.regex(for: pattern) != nil else {
            showMessage(String(localized: "This pattern cannot be used."),
                        detail: String(localized: "e.g. tiktok.com"))
            return
        }
        state.rules.add(pattern: pattern)
    }

    private func showMessage(_ text: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.informativeText = detail
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/Kyun92/fxxkscroll")!)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private var deniedBrowserNames: [String] {
        state.watcher.access
            .filter { $0.value == .denied }
            .compactMap { Browser.with(bundleID: $0.key)?.name }
            .sorted()
    }

    private func label(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }
}
