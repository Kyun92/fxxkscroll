import AppKit
import SwiftUI

/// Turning blocking off takes a full countdown. Leaving the window restarts
/// it. There is no "turn off now" button on purpose.
@MainActor
final class DisableCountdown: NSObject, NSWindowDelegate {
    final class Model: ObservableObject {
        @Published var remaining: Int
        let total: Int
        init(total: Int) { self.total = total; remaining = total }
    }

    private let model: Model
    private let onFinish: () -> Void
    private var window: NSWindow?
    private var timer: Timer?

    init(seconds: Int = 30, onFinish: @escaping () -> Void) {
        model = Model(total: seconds)
        self.onFinish = onFinish
    }

    func show() {
        if window == nil {
            let view = CountdownView(model: model) { [weak self] in self?.window?.close() }
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.styleMask = [.titled, .closable]
            window.title = "FxxkScroll"
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        model.remaining = model.total
        startTimer()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        model.remaining -= 1
        guard model.remaining <= 0 else { return }
        timer?.invalidate()
        timer = nil
        window?.close()
        onFinish()
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        guard timer != nil else { return }
        model.remaining = model.total
    }

    func windowWillClose(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
    }
}

private struct CountdownView: View {
    @ObservedObject var model: DisableCountdown.Model
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("\(model.remaining)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text("Blocking turns off at 0.")
                .font(.headline)
            Text("Leave this window and it starts over.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(model.total - model.remaining), total: Double(model.total))
                .padding(.top, 6)

            Button(action: cancel) {
                Text("Never mind").frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 300)
        .animation(.default, value: model.remaining)
    }
}
