import XCTest
import SwiftData
import StoreKit
@testable import Chronicle

/// Integration tests for the live logic: read-tracking → streak pipeline, favorites Pro-gating,
/// and the StoreKit-derived Pro state.
@MainActor
final class ChronicleLogicTests: XCTestCase {

    private func memoryModel() -> ModelContainer {
        try! ModelContainer(for: ReadDay.self, FavoriteDay.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func sampleHistory() -> HistoryStore {
        HistoryStore(entries: [
            HistoryEntry(monthDay: "01-01", year: 1801, event: "A", facts: ["1", "2", "3"]),
            HistoryEntry(monthDay: "07-20", year: 1969, event: "B", facts: ["1", "2", "3"])
        ])
    }

    private func entryA() -> HistoryEntry {
        HistoryEntry(monthDay: "01-01", year: 1801, event: "A", facts: ["1", "2", "3"])
    }

    // MARK: Read tracking → streak

    func testMarkReadUpdatesStreakAndIsIdempotentPerDay() {
        let model = AppModel(container: memoryModel(), history: sampleHistory())
        XCTAssertEqual(model.totalRead, 0)
        XCTAssertFalse(model.didReadToday)
        XCTAssertEqual(model.currentStreak, 0)

        model.markRead(entryA())
        XCTAssertEqual(model.totalRead, 1)
        XCTAssertTrue(model.didReadToday)
        XCTAssertEqual(model.currentStreak, 1)

        // Reading again the same day must NOT add a second read-day record.
        model.markRead(entryA())
        XCTAssertEqual(model.totalRead, 1)
        XCTAssertEqual(model.currentStreak, 1)
    }

    // MARK: Favorites Pro-gating (defense-in-depth)

    func testFavoritesRequirePro() {
        let model = AppModel(container: memoryModel(), history: sampleHistory())
        let store = Store()
        model.store = store   // store starts not-Pro

        // No Pro → toggling must not persist a favorite.
        let result = model.toggleFavorite(entryA())
        XCTAssertFalse(result)
        XCTAssertTrue(model.favoriteKeys.isEmpty)
        XCTAssertFalse(model.isFavorite(entryA()))
        XCTAssertTrue(model.favoriteEntries().isEmpty)
    }

    func testFavoriteEntriesResolveAgainstHistory() {
        // Directly seed a favorite record and confirm it resolves to a known history entry.
        let container = memoryModel()
        let model = AppModel(container: container, history: sampleHistory())
        container.mainContext.insert(FavoriteDay(monthDay: "07-20"))
        try? container.mainContext.save()
        model.refresh()
        XCTAssertEqual(model.favoriteKeys, ["07-20"])
        XCTAssertEqual(model.favoriteEntries().map { $0.monthDay }, ["07-20"])
    }

    // MARK: Data wipe

    func testDeleteAllDataClearsReadsAndFavorites() {
        let model = AppModel(container: memoryModel(), history: sampleHistory())
        model.markRead(entryA())
        XCTAssertEqual(model.totalRead, 1)
        model.deleteAllData()
        XCTAssertEqual(model.totalRead, 0)
        XCTAssertFalse(model.didReadToday)
        XCTAssertTrue(model.favoriteKeys.isEmpty)
    }

    // MARK: Store starts locked at the right price

    func testStoreStartsLockedAtRightPrice() async {
        let store = Store()
        try? await Task.sleep(for: .seconds(0.3))
        XCTAssertEqual(Store.productID, "chronicle_pro_unlock")
        XCTAssertEqual(store.displayPrice, "$0.99")
        XCTAssertFalse(store.isPro, "Pro must start locked")
    }
}
