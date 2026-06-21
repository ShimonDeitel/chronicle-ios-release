import Foundation

/// Loads the bundled `history.json` once at launch and serves day-entries.
/// Pure, deterministic, offline — no network, no permissions.
struct HistoryStore {
    let entries: [HistoryEntry]
    private let byKey: [String: HistoryEntry]

    init(entries: [HistoryEntry]) {
        // Keep one entry per "MM-DD"; if duplicates exist, the first wins (stable).
        var map: [String: HistoryEntry] = [:]
        for e in entries where map[e.monthDay] == nil { map[e.monthDay] = e }
        self.entries = entries
        self.byKey = map
    }

    /// Load from the app bundle. Falls back to an empty store rather than crashing.
    static func loadBundled(bundle: Bundle = .main) -> HistoryStore {
        guard let url = bundle.url(forResource: "history", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return HistoryStore(entries: [])
        }
        return decode(data)
    }

    /// Decode a JSON array of entries. Exposed for unit tests.
    static func decode(_ data: Data) -> HistoryStore {
        let decoded = (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
        return HistoryStore(entries: decoded)
    }

    var count: Int { entries.count }

    /// The entry for a calendar date, if one exists for that month/day.
    func entry(for date: Date, calendar: Calendar = .current) -> HistoryEntry? {
        byKey[HistoryEntry.key(for: date, calendar: calendar)]
    }

    /// The entry for an explicit "MM-DD" key.
    func entry(key: String) -> HistoryEntry? { byKey[key] }

    /// Today's entry, or the nearest earlier day in the calendar that we do have content for.
    /// Guarantees Home always shows something even on a date we didn't author.
    func todayOrNearest(date: Date = .now, calendar: Calendar = .current) -> HistoryEntry? {
        if let e = entry(for: date, calendar: calendar) { return e }
        // Walk back up to a year to find the closest authored day.
        var cursor = date
        for _ in 0..<366 {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
            if let e = entry(for: cursor, calendar: calendar) { return e }
        }
        return entries.sorted { $0.monthDay < $1.monthDay }.first
    }

    /// All entries sorted by month/day, optionally filtered to a single era.
    func sorted(era: Era = .all) -> [HistoryEntry] {
        let base = entries.sorted { $0.monthDay < $1.monthDay }
        guard era != .all else { return base }
        return base.filter { $0.era == era }
    }

    /// Case-insensitive search across the event headline and facts.
    func search(_ query: String, era: Era = .all) -> [HistoryEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pool = sorted(era: era)
        guard !q.isEmpty else { return pool }
        return pool.filter { e in
            e.event.lowercased().contains(q)
            || e.facts.contains { $0.lowercased().contains(q) }
            || e.longDateLabel.lowercased().contains(q)
        }
    }

    /// Look up favorites by their stored "MM-DD" keys, preserving sort order.
    func entries(forKeys keys: Set<String>) -> [HistoryEntry] {
        sorted().filter { keys.contains($0.monthDay) }
    }
}
