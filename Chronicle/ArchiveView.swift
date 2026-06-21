import SwiftUI

/// The full year of history. FREE users see today's entry and a locked teaser; PRO users get the
/// complete archive with era filtering and search.
struct ArchiveView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var era: Era = .all
    @State private var query = ""
    @State private var showPaywall = false

    private var results: [HistoryEntry] {
        appModel.history.search(query, era: era)
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isPro {
                    proArchive
                } else {
                    freeArchive
                }
            }
            .background(ChronicleBackground())
            .navigationTitle("Archive")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Pro — full searchable, era-filtered archive

    private var proArchive: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Era.selectable) { e in
                        EraChip(era: e, selected: era == e, locked: false) {
                            Haptics.tap(); era = e
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            List {
                if results.isEmpty {
                    Text("No entries match your search.")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(results) { entry in
                        NavigationLink {
                            DayDetailView(entry: entry)
                        } label: {
                            ArchiveRow(entry: entry, isFavorite: appModel.isFavorite(entry))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search events and facts")
        }
    }

    // MARK: Free — today plus an upsell

    private var freeArchive: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today")
                    .font(.headline)
                    .padding(.horizontal, 4)
                if let today = appModel.todayEntry {
                    NavigationLink {
                        DayDetailView(entry: today)
                    } label: {
                        ArchiveRow(entry: today, isFavorite: false)
                            .chronCard()
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Unlock the full archive", systemImage: "lock.fill")
                        .font(.headline)
                    Text("Browse every day of the year, filter by era, search, and save your favorites.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        Haptics.tap(); showPaywall = true
                    } label: {
                        Text("See Chronicle Pro · \(store.displayPrice)")
                            .frame(maxWidth: .infinity)
                    }
                    .prominentButton()
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .chronCard()
            }
            .padding(20)
        }
    }
}
