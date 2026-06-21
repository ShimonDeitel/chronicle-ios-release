import Foundation

/// A themed era used to filter the archive (a Pro feature). "All" is the default, free view.
/// Each entry is tagged with exactly one era by the century of its headline event.
enum Era: String, CaseIterable, Identifiable, Codable {
    case all
    case ancient        // up to 500 AD
    case medieval       // 501 - 1500
    case earlyModern    // 1501 - 1800
    case modern         // 1801 - 1945
    case contemporary   // 1946 onward

    var id: String { rawValue }

    var name: String {
        switch self {
        case .all: return "All Eras"
        case .ancient: return "Ancient"
        case .medieval: return "Medieval"
        case .earlyModern: return "Early Modern"
        case .modern: return "Modern"
        case .contemporary: return "Contemporary"
        }
    }

    /// Short blurb shown under an era heading.
    var blurb: String {
        switch self {
        case .all: return "Every day in history."
        case .ancient: return "Antiquity through 500 AD."
        case .medieval: return "The world from 501 to 1500."
        case .earlyModern: return "Discovery and revolution, 1501 to 1800."
        case .modern: return "The long nineteenth century to 1945."
        case .contemporary: return "1946 to the present day."
        }
    }

    /// Classify a four-digit year into its era. Negative years (BC) are Ancient.
    static func forYear(_ year: Int) -> Era {
        switch year {
        case ..<501: return .ancient
        case 501...1500: return .medieval
        case 1501...1800: return .earlyModern
        case 1801...1945: return .modern
        default: return .contemporary
        }
    }

    /// The eras a user can actually filter by (excludes the catch-all `.all` sentinel where needed).
    static var selectable: [Era] { [.all, .ancient, .medieval, .earlyModern, .modern, .contemporary] }
}
