import Foundation

/// Counts blocks for the current day. Resets at local midnight.
@MainActor
final class BlockCounter: ObservableObject {
    @Published private(set) var today: Int

    private let defaults: UserDefaults
    private static let countKey = "blockCount"
    private static let dayKey = "blockCountDay"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        today = defaults.string(forKey: Self.dayKey) == Self.dayStamp()
            ? defaults.integer(forKey: Self.countKey)
            : 0
    }

    /// Re-reads the day so a menu opened after midnight shows 0.
    func refresh() {
        if defaults.string(forKey: Self.dayKey) != Self.dayStamp() { today = 0 }
    }

    @discardableResult
    func increment() -> Int {
        refresh()
        today += 1
        defaults.set(today, forKey: Self.countKey)
        defaults.set(Self.dayStamp(), forKey: Self.dayKey)
        return today
    }

    private static func dayStamp(_ date: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }
}
