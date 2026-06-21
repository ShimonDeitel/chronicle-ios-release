import SwiftUI

/// Today's chronicle: the streak banner plus today's full entry. Reading it marks the streak.
struct HomeView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showShare = false
    @State private var showPaywall = false
    @State private var shareImage: UIImage?

    private var entry: HistoryEntry? { appModel.todayEntry }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    streakBanner
                    if let entry {
                        todayHeader(entry)
                        eventCard(entry)
                        factsCard(entry)
                        actions(entry)
                    } else {
                        emptyState
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(20)
            }
            .background(ChronicleBackground())
            .navigationTitle("Today")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showShare) {
                if let img = shareImage { ShareSheet(items: [img]) }
            }
            .onAppear { if let entry { appModel.markRead(entry) } }
        }
    }

    // MARK: Sections

    private var streakBanner: some View {
        HStack(spacing: 16) {
            StreakBadge(days: appModel.currentStreak)
            VStack(alignment: .leading, spacing: 3) {
                Text(appModel.didReadToday ? "Read today" : "Read today's chronicle")
                    .font(.headline)
                Text(streakSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chronCard()
    }

    private var streakSubtitle: String {
        if appModel.currentStreak == 0 { return "Start your reading streak." }
        let best = appModel.longestStreak
        return "Current streak \(appModel.currentStreak) · best \(best)"
    }

    private func todayHeader(_ entry: HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.longDateLabel.uppercased()) · \(entry.era.name.uppercased())")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(Color.chronAccent)
            Text(entry.yearLabel)
                .font(.system(size: 40, weight: .bold, design: .rounded))
        }
    }

    private func eventCard(_ entry: HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("On this day", systemImage: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(entry.event)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chronCard()
    }

    private func factsCard(_ entry: HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Three facts", systemImage: "lightbulb")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(entry.facts.enumerated()), id: \.offset) { idx, fact in
                FactRow(index: idx + 1, text: fact)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chronCard()
    }

    private func actions(_ entry: HistoryEntry) -> some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                if store.isPro {
                    if appModel.toggleFavorite(entry) { Haptics.success() }
                } else {
                    showPaywall = true
                }
            } label: {
                Label(appModel.isFavorite(entry) ? "Favorited" : "Favorite",
                      systemImage: appModel.isFavorite(entry) ? "star.fill" : "star")
                    .frame(maxWidth: .infinity)
            }
            .softButton()

            Button {
                Haptics.tap()
                shareImage = HistoryCard(entry: entry).render()
                if shareImage != nil { showShare = true }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .softButton()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No entry available")
                .font(.headline)
            Text("History content could not be loaded.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
