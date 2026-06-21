import SwiftUI

/// Saved days. A Pro feature: free users see an upsell, Pro users see their saved entries.
struct FavoritesView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showPaywall = false

    private var favorites: [HistoryEntry] { appModel.favoriteEntries() }

    var body: some View {
        NavigationStack {
            Group {
                if !store.isPro {
                    upsell
                } else if favorites.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(favorites) { entry in
                            NavigationLink {
                                DayDetailView(entry: entry)
                            } label: {
                                ArchiveRow(entry: entry, isFavorite: true)
                            }
                        }
                        .onDelete { idx in
                            idx.map { favorites[$0] }.forEach { appModel.toggleFavorite($0) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(ChronicleBackground())
            .navigationTitle("Favorites")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var upsell: some View {
        VStack(spacing: 14) {
            Image(systemName: "star")
                .font(.system(size: 44))
                .foregroundStyle(Color.chronAccent)
            Text("Save your favorite days")
                .font(.title3.weight(.semibold))
            Text("Chronicle Pro lets you favorite any day in history and keep them all here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap(); showPaywall = true
            } label: {
                Text("Unlock Chronicle Pro · \(store.displayPrice)")
            }
            .prominentButton()
            .padding(.top, 4)
        }
        .padding(32)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "star")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No favorites yet")
                .font(.headline)
            Text("Tap the star on any day to save it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
