import Foundation

/// Builds the address a blocked tab is sent to. Only the service name
/// (youtube, instagram, ...) and today's count are passed, never the URL.
enum BlockPage {
    static func url(blockedURL: String, count: Int) -> String {
        guard let page = Bundle.main.url(forResource: "blocked", withExtension: "html"),
              var components = URLComponents(url: page, resolvingAgainstBaseURL: false)
        else { return "about:blank" }

        let language = Locale.preferredLanguages.first?.hasPrefix("ko") == true ? "ko" : "en"
        components.queryItems = [
            URLQueryItem(name: "s", value: Matcher.serviceName(for: blockedURL)),
            URLQueryItem(name: "n", value: String(count)),
            URLQueryItem(name: "lang", value: language),
        ]
        return components.url?.absoluteString ?? "about:blank"
    }
}
