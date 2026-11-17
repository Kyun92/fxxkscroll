import Foundation

struct Rule: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var pattern: String
    var isEnabled = true

    static let defaults: [Rule] = [
        Rule(pattern: "youtube.com/shorts/*"),
        Rule(pattern: "instagram.com/reels/*"),
        Rule(pattern: "instagram.com/reel/*"),
        Rule(pattern: "tiktok.com/*"),
    ]
}
