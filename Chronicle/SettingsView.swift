import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @AppStorage("chronicle.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var showPaywall = false
    @State private var restoreMessage: String?

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Chronicle \(v)"
    }

    var body: some View {
        NavigationStack {
            Form {
                streakSection
                proSection
                appearanceSection
                aboutSection
            }
            .navigationTitle("Settings")
            .tint(Color.chronAccent)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var streakSection: some View {
        Section {
            HStack(spacing: 14) {
                MetricTile(value: "\(appModel.currentStreak)", label: "Current streak")
                MetricTile(value: "\(appModel.longestStreak)", label: "Best streak")
                MetricTile(value: "\(appModel.totalRead)", label: "Days read")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if store.isPro {
                HStack {
                    Label("Chronicle Pro", systemImage: "sparkles")
                    Spacer()
                    Text("Unlocked").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Haptics.tap(); showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Chronicle Pro", systemImage: "sparkles")
                        Spacer()
                        Text(store.displayPrice).foregroundStyle(.secondary)
                    }
                }
                Button("Restore Purchase") {
                    Task {
                        await store.restore()
                        restoreMessage = store.isPro ? "Restored." : "No previous purchase found."
                    }
                }
                if let restoreMessage {
                    Text(restoreMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !store.isPro {
                Text("One-time purchase. The full archive, themed eras, search and favorites.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeRaw) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var aboutSection: some View {
        Section {
            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/chronicle-site/privacy.html")!)
        } footer: {
            Text(version).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
        }
    }
}
