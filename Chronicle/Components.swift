import SwiftUI

/// A circular streak badge — flat Apple-blue ring with the day count at its center.
struct StreakBadge: View {
    let days: Int
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.chronAccent.opacity(0.10))
            Circle()
                .strokeBorder(Color.chronAccent.opacity(0.35), lineWidth: 1.5)
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.chronAccent)
                Text(days == 1 ? "day" : "days")
                    .font(.system(size: size * 0.16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityIdentifier("streak-badge")
    }
}

/// A single lesser-known fact, numbered and indented like an Apple list row.
struct FactRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.chronAccent)
                .frame(width: 22, height: 22)
                .background(Color.chronAccent.opacity(0.12), in: Circle())
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// A selectable era chip; shows a small lock when the user isn't Pro.
struct EraChip: View {
    let era: Era
    let selected: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(era.name).font(.subheadline.weight(.semibold))
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(
                selected ? Color.chronAccent : Color.chronCard,
                in: Capsule()
            )
            .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("era-\(era.id)")
    }
}

/// A compact archive row — month/day label plus the headline event, with a favorite glyph.
struct ArchiveRow: View {
    let entry: HistoryEntry
    let isFavorite: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(entry.monthAbbrev).font(.caption2.weight(.bold)).foregroundStyle(Color.chronAccent)
                Text("\(entry.day)").font(.title3.weight(.bold))
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.event)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(entry.era.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Color.chronAccent)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// A small labelled metric tile used on Settings / Home.
struct MetricTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.chronAccent)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.chronCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Wraps UIActivityViewController so we can share a rendered history card image.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
