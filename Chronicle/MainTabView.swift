import SwiftUI

/// The four primary destinations: Today, Archive, Favorites, Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            ArchiveView()
                .tabItem { Label("Archive", systemImage: "calendar") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Color.chronAccent)
    }
}
