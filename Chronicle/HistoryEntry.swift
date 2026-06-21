import Foundation

/// One day in history, decoded from the bundled `history.json`.
/// `monthDay` is the canonical "MM-DD" key (e.g. "07-04"); `year` is the headline event's year.
/// All content is factual, public-domain history authored for this app — no copyrighted prose.
struct HistoryEntry: Codable, Identifiable, Equatable {
    let monthDay: String   // "MM-DD"
    let year: Int          // year of the headline event (negative = BC)
    let event: String      // the major event, one sentence
    let facts: [String]    // 3 lesser-known facts

    var id: String { monthDay }

    var month: Int { Int(monthDay.prefix(2)) ?? 1 }
    var day: Int { Int(monthDay.suffix(2)) ?? 1 }

    var era: Era { Era.forYear(year) }

    /// "July 4" style label, locale-independent (uses a fixed English month table for stability).
    var longDateLabel: String { "\(Self.monthName(month)) \(day)" }

    /// "JUL" style abbreviation for compact rows.
    var monthAbbrev: String { Self.monthAbbrev(month) }

    /// "44 BC" / "1969" formatted year for display.
    var yearLabel: String { year < 0 ? "\(-year) BC" : "\(year)" }

    static func monthName(_ m: Int) -> String {
        let names = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        guard (1...12).contains(m) else { return "" }
        return names[m - 1]
    }

    static func monthAbbrev(_ m: Int) -> String {
        let names = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                     "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        guard (1...12).contains(m) else { return "" }
        return names[m - 1]
    }

    /// Canonical "MM-DD" key for a given Date.
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return String(format: "%02d-%02d", c.month ?? 1, c.day ?? 1)
    }
}
