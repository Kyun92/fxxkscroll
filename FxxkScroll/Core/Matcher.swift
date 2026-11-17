import Foundation

/// Matches browser URLs against user-defined wildcard patterns such as
/// `youtube.com/shorts/*`. Only `*` is special. Scheme, `www.` and `m.` are
/// ignored, and a pattern host also matches its subdomains.
struct Matcher: @unchecked Sendable {
    private let compiled: [(rule: Rule, regex: NSRegularExpression)]

    init(rules: [Rule]) {
        compiled = rules.filter(\.isEnabled).compactMap { rule in
            guard let regex = Matcher.regex(for: rule.pattern) else { return nil }
            return (rule, regex)
        }
    }

    /// Returns the first enabled rule that matches `url`, or nil.
    func firstMatch(for url: String) -> Rule? {
        guard let target = Matcher.normalize(url: url) else { return nil }
        let range = NSRange(target.startIndex..., in: target)
        return compiled.first { $0.regex.firstMatch(in: target, range: range) != nil }?.rule
    }

    // MARK: - Normalization

    /// `https://m.YouTube.com/shorts/abc?x=1` -> `youtube.com/shorts/abc?x=1`
    static func normalize(url: String) -> String? {
        guard let components = URLComponents(string: url.trimmingCharacters(in: .whitespaces)),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host?.lowercased(), !host.isEmpty
        else { return nil }

        var result = stripCommonPrefixes(host) + components.percentEncodedPath
        if let query = components.percentEncodedQuery { result += "?" + query }
        return result
    }

    static func normalize(pattern: String) -> String {
        var p = pattern.trimmingCharacters(in: .whitespaces)
        if let range = p.range(of: "://") { p = String(p[range.upperBound...]) }
        let slash = p.firstIndex(of: "/") ?? p.endIndex
        let host = stripCommonPrefixes(String(p[..<slash]).lowercased())
        return host + p[slash...]
    }

    private static func stripCommonPrefixes(_ host: String) -> String {
        for prefix in ["www.", "m."] where host.hasPrefix(prefix) {
            return String(host.dropFirst(prefix.count))
        }
        return host
    }

    // MARK: - Pattern compilation

    static func regex(for pattern: String) -> NSRegularExpression? {
        let normalized = normalize(pattern: pattern)
        guard !normalized.isEmpty, normalized != "*" else { return nil }

        let escaped = normalized
            .split(separator: "*", omittingEmptySubsequences: false)
            .map { NSRegularExpression.escapedPattern(for: String($0)) }
            .joined(separator: ".*")

        // Pattern host also matches subdomains (vm.tiktok.com for tiktok.com),
        // unless the pattern already starts with a wildcard.
        let subdomain = normalized.hasPrefix("*") ? "" : "(?:[a-z0-9-]+\\.)*"
        // `youtube.com` alone should match every page on the site.
        let tail = normalized.contains("/") ? "" : "(?:[/?].*)?"
        return try? NSRegularExpression(pattern: "^" + subdomain + escaped + tail + "$",
                                        options: [.caseInsensitive])
    }

    /// A pattern for the section a URL belongs to:
    /// `https://www.facebook.com/reel/123?x=1` -> `facebook.com/reel/*`,
    /// `https://x.com/` -> `x.com`.
    static func suggestedPattern(for url: String) -> String? {
        guard let components = URLComponents(string: url),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host?.lowercased(), !host.isEmpty
        else { return nil }

        let site = stripCommonPrefixes(host)
        guard let first = components.path.split(separator: "/").first else { return site }
        return "\(site)/\(first)/*"
    }

    /// Short service name for the block page, e.g. `youtube` for `vm.youtube.com`.
    static func serviceName(for url: String) -> String {
        guard let host = URLComponents(string: url)?.host?.lowercased() else { return "web" }
        let labels = host.split(separator: ".")
        return labels.count >= 2 ? String(labels[labels.count - 2]) : host
    }
}
