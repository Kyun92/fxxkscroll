import Foundation

/// Block rules, saved as JSON in Application Support so they are easy to
/// back up or edit by hand.
@MainActor
final class RuleStore: ObservableObject {
    @Published var rules: [Rule] { didSet { save() } }

    private let fileURL: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FxxkScroll", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("rules.json")

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Rule].self, from: data) {
            rules = saved
        } else {
            rules = Rule.defaults
        }
    }

    var matcher: Matcher { Matcher(rules: rules) }

    func add(pattern: String) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !rules.contains(where: { Matcher.normalize(pattern: $0.pattern) == Matcher.normalize(pattern: trimmed) })
        else { return }
        rules.append(Rule(pattern: trimmed))
    }

    func remove(id: Rule.ID) {
        rules.removeAll { $0.id == id }
    }

    func toggle(id: Rule.ID) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[index].isEnabled.toggle()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(rules) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
