import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store (read-days + favorites), the bundled HistoryStore,
/// derives the read streak, and manages favorites (a Pro feature). Stats are always derived
/// from records — never stored as truth.
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    let history: HistoryStore
    weak var store: Store?

    @Published private(set) var currentStreak = 0
    @Published private(set) var longestStreak = 0
    @Published private(set) var totalRead = 0
    @Published private(set) var didReadToday = false
    @Published private(set) var favoriteKeys: Set<String> = []

    init(container: ModelContainer, history: HistoryStore = .loadBundled()) {
        self.container = container
        self.history = history
        #if DEBUG
        seedIfRequested()
        #endif
        refresh()
    }

    // MARK: Container (local-only on-device persistence)

    static func makeContainer() -> ModelContainer {
        let schema = Schema([ReadDay.self, FavoriteDay.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        // Last resort so the app never crashes on launch.
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Read tracking

    /// Mark today as read for the given entry. At most one read-record is kept per calendar day.
    func markRead(_ entry: HistoryEntry, on date: Date = .now) {
        let ctx = container.mainContext
        let cal = Calendar.current
        let all = (try? ctx.fetch(FetchDescriptor<ReadDay>())) ?? []
        let already = all.contains { cal.isDate($0.date, inSameDayAs: date) }
        if !already {
            ctx.insert(ReadDay(date: date, monthDay: entry.monthDay))
            try? ctx.save()
        }
        refresh()
    }

    private func readDays() -> [ReadDay] {
        (try? container.mainContext.fetch(FetchDescriptor<ReadDay>())) ?? []
    }

    // MARK: Favorites (Pro)

    func isFavorite(_ entry: HistoryEntry) -> Bool { favoriteKeys.contains(entry.monthDay) }

    /// Toggle a favorite. Defense-in-depth: never persists a favorite for a non-Pro user,
    /// even if a caller reaches here past the UI gate. Returns the new favorite state.
    @discardableResult
    func toggleFavorite(_ entry: HistoryEntry) -> Bool {
        guard store?.isPro == true else { return false }
        let ctx = container.mainContext
        let all = (try? ctx.fetch(FetchDescriptor<FavoriteDay>())) ?? []
        if let existing = all.first(where: { $0.monthDay == entry.monthDay }) {
            ctx.delete(existing)
            try? ctx.save()
            refreshFavorites()
            return false
        } else {
            ctx.insert(FavoriteDay(monthDay: entry.monthDay))
            try? ctx.save()
            refreshFavorites()
            return true
        }
    }

    func favoriteEntries() -> [HistoryEntry] {
        history.entries(forKeys: favoriteKeys)
    }

    private func refreshFavorites() {
        let all = (try? container.mainContext.fetch(FetchDescriptor<FavoriteDay>())) ?? []
        favoriteKeys = Set(all.map { $0.monthDay })
    }

    // MARK: Stats

    func refresh() {
        let all = readDays()
        totalRead = Set(all.map { Calendar.current.startOfDay(for: $0.date) }).count

        let cal = Calendar.current
        let days = Set(all.map { cal.startOfDay(for: $0.date) })
        didReadToday = days.contains(cal.startOfDay(for: .now))
        currentStreak = Self.currentStreak(days: days, cal: cal)
        longestStreak = Self.longestStreak(days: days, cal: cal)
        refreshFavorites()
    }

    nonisolated static func currentStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        var day = cal.startOfDay(for: .now)
        // If today isn't logged yet, the streak still stands as of yesterday.
        if !days.contains(day) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day), days.contains(yesterday)
            else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    nonisolated static func longestStreak(days: Set<Date>, cal: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1, run = 1
        for i in 1..<sorted.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]), prev == sorted[i] {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        return best
    }

    // MARK: Today

    var todayEntry: HistoryEntry? { history.todayOrNearest() }

    // MARK: Account deletion / data wipe

    /// Erase all on-device data (used by Delete Account).
    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: ReadDay.self)
        try? ctx.delete(model: FavoriteDay.self)
        try? ctx.save()
        favoriteKeys.removeAll()
        refresh()
    }

    // MARK: DEBUG seeding (compiled out of Release)

    #if DEBUG
    private func seedIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let n = env["CHRONICLE_SEED"].flatMap(Int.init), n > 0 else { return }
        let ctx = container.mainContext
        if ((try? ctx.fetch(FetchDescriptor<ReadDay>()))?.isEmpty ?? true) {
            let cal = Calendar.current
            for offset in 0..<n {
                if let day = cal.date(byAdding: .day, value: -offset, to: .now) {
                    ctx.insert(ReadDay(date: day, monthDay: HistoryEntry.key(for: day)))
                }
            }
            try? ctx.save()
        }
    }
    #endif
}
