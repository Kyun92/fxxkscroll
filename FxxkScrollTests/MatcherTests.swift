import XCTest
@testable import FxxkScroll

final class MatcherTests: XCTestCase {
    private let matcher = Matcher(rules: Rule.defaults)

    private func blocks(_ url: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(matcher.firstMatch(for: url), "\(url) should be blocked", file: file, line: line)
    }

    private func allows(_ url: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(matcher.firstMatch(for: url), "\(url) should be allowed", file: file, line: line)
    }

    func testBlocksShortFormPages() {
        blocks("https://www.youtube.com/shorts/abc123")
        blocks("https://m.youtube.com/shorts/abc123?feature=share")
        blocks("https://youtube.com/shorts/abc123")
        blocks("https://www.instagram.com/reels/C1a2b3/")
        blocks("https://www.instagram.com/reels/")
        blocks("https://www.instagram.com/reel/C1a2b3/")
        blocks("https://www.tiktok.com/@someone/video/123")
        blocks("https://vm.tiktok.com/ZM123/")
        blocks("https://www.tiktok.com/")
        blocks("HTTPS://WWW.YOUTUBE.COM/shorts/abc")
    }

    func testAllowsRestOfSite() {
        allows("https://www.youtube.com/")
        allows("https://www.youtube.com/watch?v=abc123")
        allows("https://www.youtube.com/@channel/videos")
        allows("https://www.youtube.com/results?search_query=shorts")
        allows("https://www.instagram.com/")
        allows("https://www.instagram.com/p/C1a2b3/")
        allows("https://www.instagram.com/someone/")
    }

    func testIgnoresLookalikeHostsAndNonWebSchemes() {
        allows("https://notyoutube.com/shorts/abc")
        allows("https://youtube.com.evil.example/shorts/abc")
        allows("file:///Users/me/blocked.html?s=youtube")
        allows("chrome://settings")
        allows("about:blank")
        allows("")
    }

    func testDisabledRuleIsIgnored() {
        var rules = Rule.defaults
        rules[0].isEnabled = false
        XCTAssertNil(Matcher(rules: rules).firstMatch(for: "https://www.youtube.com/shorts/abc"))
    }

    func testUserPatterns() {
        let m = Matcher(rules: [
            Rule(pattern: "https://www.facebook.com/reel/*"),
            Rule(pattern: "x.com"),
            Rule(pattern: "*google.com/search?*tbm=vid*"),
        ])
        XCTAssertNotNil(m.firstMatch(for: "https://m.facebook.com/reel/123"))
        XCTAssertNotNil(m.firstMatch(for: "https://x.com/home"))
        XCTAssertNotNil(m.firstMatch(for: "https://x.com"))
        XCTAssertNil(m.firstMatch(for: "https://xx.com"))
        XCTAssertNotNil(m.firstMatch(for: "https://www.google.com/search?q=cats&tbm=vid"))
        XCTAssertNil(m.firstMatch(for: "https://www.google.com/search?q=cats"))
    }

    func testCatchAllPatternIsRejected() {
        XCTAssertNil(Matcher.regex(for: "*"))
        XCTAssertNil(Matcher.regex(for: "   "))
    }

    func testServiceName() {
        XCTAssertEqual(Matcher.serviceName(for: "https://m.youtube.com/shorts/a"), "youtube")
        XCTAssertEqual(Matcher.serviceName(for: "https://www.instagram.com/reel/a"), "instagram")
        XCTAssertEqual(Matcher.serviceName(for: "https://vm.tiktok.com/a"), "tiktok")
    }

    func testSuggestedPattern() {
        XCTAssertEqual(Matcher.suggestedPattern(for: "https://www.facebook.com/reel/123?x=1"), "facebook.com/reel/*")
        XCTAssertEqual(Matcher.suggestedPattern(for: "https://m.youtube.com/shorts/abc"), "youtube.com/shorts/*")
        XCTAssertEqual(Matcher.suggestedPattern(for: "https://x.com/"), "x.com")
        XCTAssertNil(Matcher.suggestedPattern(for: "file:///tmp/blocked.html"))
    }
}
