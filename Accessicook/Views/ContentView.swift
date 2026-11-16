import SwiftUI

enum AppTab: String {
    case browse, search, favorites, more
}

/// Four tabs, each with a text label, so VoiceOver can land on them directly.
struct ContentView: View {
    @SceneStorage("Accessicook.selectedTab") private var tabName: String = AppTab.browse.rawValue

    private var tab: Binding<String> { $tabName }

    var body: some View {
        TabView(selection: tab) {
            BrowseView()
                .tabItem { Label("Browse", systemImage: "books.vertical") }
                .tag(AppTab.browse.rawValue)
                .accessibilityIdentifier("tabBrowse")
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search.rawValue)
                .accessibilityIdentifier("tabSearch")
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }
                .tag(AppTab.favorites.rawValue)
                .accessibilityIdentifier("tabFavorites")
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(AppTab.more.rawValue)
                .accessibilityIdentifier("tabMore")
        }
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: Route.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    NavigationLink(value: Route.recents) {
                        Label("Recently Viewed", systemImage: "clock")
                    }
                } header: {
                    SectionHeader("On this iPhone")
                }
                Section {
                    NavigationLink(value: Route.about) {
                        Label("About Accessicook", systemImage: "info.circle")
                    }
                    NavigationLink(value: Route.privacy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                } header: {
                    SectionHeader("About")
                }
            }
            .navigationTitle("More")
            .accessicookDestinations()
        }
    }
}
