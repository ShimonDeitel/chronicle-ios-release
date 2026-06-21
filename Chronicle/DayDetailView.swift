import SwiftUI

/// The full reading view for a single day in history: headline event + three lesser-known facts,
/// with favorite (Pro) and share actions. Shared by Home, Archive and Favorites.
struct DayDetailView: View {
    let entry: HistoryEntry
    /// When true, marks the entry as read on appear (Home only) to drive the streak.
    var marksReadOnAppear = false

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showShare = false
    @State private var showPaywall = false
    @State private var shareImage: UIImage?

    private var isFavorite: Bool { appModel.isFavorite(entry) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                eventCard
                factsCard
                actions
                Color.clear.frame(height: 8)
            }
            .padding(20)
        }
        .background(ChronicleBackground())
        .navigationTitle(entry.longDateLabel)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showShare) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .onAppear {
            if marksReadOnAppear { appModel.markRead(entry) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.era.name.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(Color.chronAccent)
            Text(entry.yearLabel)
                .font(.system(size: 40, weight: .bold, design: .rounded))
        }
    }

    private var eventCard: some View {
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

    private var factsCard: some View {
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

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                if store.isPro {
                    let now = appModel.toggleFavorite(entry)
                    if now { Haptics.success() }
                } else {
                    showPaywall = true
                }
            } label: {
                Label(isFavorite ? "Favorited" : "Favorite",
                      systemImage: isFavorite ? "star.fill" : "star")
                    .frame(maxWidth: .infinity)
            }
            .softButton()
            .accessibilityIdentifier("favorite-button")

            Button {
                Haptics.tap()
                shareImage = HistoryCard(entry: entry).render()
                if shareImage != nil { showShare = true }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .softButton()
            .accessibilityIdentifier("share-button")
        }
    }
}
