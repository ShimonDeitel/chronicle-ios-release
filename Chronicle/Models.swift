import Foundation
import SwiftData

/// A record that the user read the day's chronicle on a given calendar day. Drives the read streak.
/// All properties have defaults and there are no unique constraints, so the schema is
/// CloudKit-mirroring compatible (private database).
@Model
final class ReadDay {
    var id: UUID = UUID()
    var date: Date = Date.now       // when the read happened
    var monthDay: String = ""       // the "MM-DD" entry that was read

    init(id: UUID = UUID(), date: Date = .now, monthDay: String = "") {
        self.id = id
        self.date = date
        self.monthDay = monthDay
    }
}

/// A favorited day (Pro feature). Keyed by the entry's "MM-DD".
@Model
final class FavoriteDay {
    var id: UUID = UUID()
    var monthDay: String = ""
    var addedAt: Date = Date.now

    init(id: UUID = UUID(), monthDay: String = "", addedAt: Date = .now) {
        self.id = id
        self.monthDay = monthDay
        self.addedAt = addedAt
    }
}
