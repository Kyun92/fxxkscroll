import Foundation

/// Runs AppleScript on one private serial queue so a slow or hung browser
/// never blocks the menu. NSAppleScript instances never leave this queue.
final class ScriptRunner: @unchecked Sendable {
    enum Failure: Error, Equatable {
        /// The user has not allowed (or has denied) Automation for this browser.
        case notAuthorized
        case failed(code: Int, message: String)
    }

    let queue = DispatchQueue(label: "fxxkscroll.applescript", qos: .userInitiated)
    private var cache: [String: NSAppleScript] = [:]

    /// Must be called on `queue`.
    func run(_ source: String, cacheable: Bool = true) -> Result<NSAppleEventDescriptor, Failure> {
        dispatchPrecondition(condition: .onQueue(queue))

        let script: NSAppleScript
        if cacheable, let cached = cache[source] {
            script = cached
        } else {
            guard let fresh = NSAppleScript(source: source) else {
                return .failure(.failed(code: 0, message: "Could not create script"))
            }
            script = fresh
            if cacheable { cache[source] = fresh }
        }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            let message = error[NSAppleScript.errorMessage] as? String ?? ""
            // -1743: not authorized, -1744: would need to ask the user.
            if code == -1743 || code == -1744 { return .failure(.notAuthorized) }
            return .failure(.failed(code: code, message: message))
        }
        return .success(result)
    }
}
