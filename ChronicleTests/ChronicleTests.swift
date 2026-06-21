import XCTest
@testable import Chronicle

final class ChronicleTests: XCTestCase {

    // MARK: - Era classification

    func testEraForYearBoundaries() {
        XCTAssertEqual(Era.forYear(-44), .ancient)        // 44 BC
        XCTAssertEqual(Era.forYear(79), .ancient)
        XCTAssertEqual(Era.forYear(500), .ancient)
        XCTAssertEqual(Era.forYear(501), .medieval)
        XCTAssertEqual(Era.forYear(1500), .medieval)
        XCTAssertEqual(Era.forYear(1501), .earlyModern)
        XCTAssertEqual(Era.forYear(1800), .earlyModern)
        XCTAssertEqual(Era.forYear(1801), .modern)
        XCTAssertEqual(Era.forYear(1945), .modern)
        XCTAssertEqual(Era.forYear(1946), .contemporary)
        XCTAssertEqual(Era.forYear(1969), .contemporary)
    }

    // MARK: - HistoryEntry formatting

    func testEntryDateAndYearLabels() {
        let e = HistoryEntry(monthDay: "07-04", year: 1776, event: "Test event",
                             facts: ["a", "b", "c"])
        XCTAssertEqual(e.month, 7)
        XCTAssertEqual(e.day, 4)
        XCTAssertEqual(e.longDateLabel, "July 4")
        XCTAssertEqual(e.monthAbbrev, "JUL")
        XCTAssertEqual(e.yearLabel, "1776")
        XCTAssertEqual(e.era, .earlyModern)
    }

    func testBCYearLabel() {
        let e = HistoryEntry(monthDay: "03-15", year: -44, event: "Caesar",
                             facts: ["a", "b", "c"])
        XCTAssertEqual(e.yearLabel, "44 BC")
        XCTAssertEqual(e.era, .ancient)
    }

    func testKeyForDateIsZeroPadded() {
        var comps = DateComponents()
        comps.year = 2024; comps.month = 1; comps.day = 9
        let date = Calendar.current.date(from: comps)!
        XCTAssertEqual(HistoryEntry.key(for: date), "01-09")
    }

    // MARK: - HistoryStore lookups, filtering & search

    private func sampleStore() -> HistoryStore {
        HistoryStore(entries: [
            HistoryEntry(monthDay: "01-01", year: 1801, event: "United Kingdom formed",
                         facts: ["parliaments merged", "new flag", "new century"]),
            HistoryEntry(monthDay: "03-15", year: -44, event: "Caesar assassinated in the Senate",
                         facts: ["Ides of March", "civil war", "first emperor"]),
            HistoryEntry(monthDay: "07-20", year: 1969, event: "First Moon walk",
                         facts: ["bootprints", "famous line", "watched worldwide"])
        ])
    }

    func testStoreLookupByKey() {
        let store = sampleStore()
        XCTAssertEqual(store.count, 3)
        XCTAssertEqual(store.entry(key: "03-15")?.year, -44)
        XCTAssertNil(store.entry(key: "12-25"))
    }

    func testStoreSortedByMonthDay() {
        let store = sampleStore()
        XCTAssertEqual(store.sorted().map { $0.monthDay }, ["01-01", "03-15", "07-20"])
    }

    func testStoreEraFilter() {
        let store = sampleStore()
        XCTAssertEqual(store.sorted(era: .ancient).map { $0.monthDay }, ["03-15"])
        XCTAssertEqual(store.sorted(era: .contemporary).map { $0.monthDay }, ["07-20"])
        XCTAssertEqual(store.sorted(era: .all).count, 3)
    }

    func testStoreSearchAcrossEventAndFacts() {
        let store = sampleStore()
        XCTAssertEqual(store.search("caesar").map { $0.monthDay }, ["03-15"])
        XCTAssertEqual(store.search("Ides").map { $0.monthDay }, ["03-15"]) // matches a fact
        XCTAssertEqual(store.search("moon").map { $0.monthDay }, ["07-20"])
        XCTAssertEqual(store.search("").count, 3) // empty query returns all
    }

    func testTodayOrNearestFallsBackWhenDateMissing() {
        let store = sampleStore()
        // A date with no authored entry (Dec 31) should still return *something*.
        var comps = DateComponents()
        comps.year = 2024; comps.month = 12; comps.day = 31
        let date = Calendar.current.date(from: comps)!
        XCTAssertNotNil(store.todayOrNearest(date: date))
    }

    func testEntriesForKeysPreservesSortOrder() {
        let store = sampleStore()
        let result = store.entries(forKeys: ["07-20", "01-01"])
        XCTAssertEqual(result.map { $0.monthDay }, ["01-01", "07-20"])
    }

    // MARK: - Bundled dataset integrity (the real history.json shipped in the app)

    func testBundledDatasetIsLargeAndWellFormed() throws {
        let store = HistoryStore.loadBundled(bundle: Bundle(for: Self.self))
        // The test bundle may not carry the resource; only assert structure when present.
        guard store.count > 0 else {
            throw XCTSkip("history.json not in test bundle; validated in app target")
        }
        XCTAssertGreaterThanOrEqual(store.count, 180)
        for e in store.entries {
            XCTAssertEqual(e.facts.count, 3, "every entry must have exactly three facts")
            XCTAssertFalse(e.event.isEmpty)
            XCTAssertEqual(e.monthDay.count, 5)
        }
    }

    // MARK: - Streak math

    private func days(_ offsets: [Int], cal: Calendar) -> Set<Date> {
        let today = cal.startOfDay(for: Date())
        return Set(offsets.compactMap { cal.date(byAdding: .day, value: -$0, to: today) })
    }

    func testCurrentStreakCountsTodayBackwards() {
        let cal = Calendar.current
        XCTAssertEqual(AppModel.currentStreak(days: days([0, 1, 2], cal: cal), cal: cal), 3)
    }

    func testCurrentStreakHoldsWhenTodayNotYetLogged() {
        let cal = Calendar.current
        XCTAssertEqual(AppModel.currentStreak(days: days([1, 2], cal: cal), cal: cal), 2)
    }

    func testCurrentStreakBreaksWithGap() {
        let cal = Calendar.current
        XCTAssertEqual(AppModel.currentStreak(days: days([0, 2, 3], cal: cal), cal: cal), 1)
        XCTAssertEqual(AppModel.currentStreak(days: [], cal: cal), 0)
    }

    func testLongestStreak() {
        let cal = Calendar.current
        XCTAssertEqual(AppModel.longestStreak(days: days([0, 1, 2, 5, 6], cal: cal), cal: cal), 3)
    }

    // MARK: - Store product id / price

    @MainActor
    func testProductIDIsChroniclePro() {
        XCTAssertEqual(Store.productID, "chronicle_pro_unlock")
    }
}
