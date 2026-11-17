import Foundation

/// A browser FxxkScroll can read and redirect through AppleScript.
struct Browser: Hashable, Sendable {
    enum Family: Sendable {
        /// Chrome-like scripting dictionary: `active tab of window`.
        case chromium
        /// Safari dictionary: `current tab of window`.
        case safari
    }

    let name: String
    let bundleID: String
    let family: Family

    static let all: [Browser] = [
        Browser(name: "Google Chrome", bundleID: "com.google.Chrome", family: .chromium),
        Browser(name: "Safari", bundleID: "com.apple.Safari", family: .safari),
        Browser(name: "Arc", bundleID: "company.thebrowser.Browser", family: .chromium),
        Browser(name: "Microsoft Edge", bundleID: "com.microsoft.edgemac", family: .chromium),
        Browser(name: "Brave", bundleID: "com.brave.Browser", family: .chromium),
        Browser(name: "Vivaldi", bundleID: "com.vivaldi.Vivaldi", family: .chromium),
        Browser(name: "Chromium", bundleID: "org.chromium.Chromium", family: .chromium),
        Browser(name: "Safari Technology Preview", bundleID: "com.apple.SafariTechnologyPreview", family: .safari),
    ]

    static func with(bundleID: String) -> Browser? {
        all.first { $0.bundleID == bundleID }
    }

    private var tabProperty: String {
        switch family {
        case .chromium: "active tab"
        case .safari: "current tab"
        }
    }

    /// Returns `{{windowID, url}, ...}` for the visible tab of every window.
    var readTabsScript: String {
        """
        with timeout of 2 seconds
            tell application id "\(bundleID)"
                set out to {}
                repeat with w in windows
                    try
                        set end of out to {id of w, URL of \(tabProperty) of w}
                    end try
                end repeat
                return out
            end tell
        end timeout
        """
    }

    var frontTabScript: String {
        """
        with timeout of 2 seconds
            tell application id "\(bundleID)" to return URL of \(tabProperty) of front window
        end timeout
        """
    }

    func redirectScript(windowID: Int, to url: String) -> String {
        let escaped = url
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return """
        with timeout of 2 seconds
            tell application id "\(bundleID)"
                set URL of \(tabProperty) of (first window whose id is \(windowID)) to "\(escaped)"
            end tell
        end timeout
        """
    }
}
