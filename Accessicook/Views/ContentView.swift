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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("On this iPhone")
                        .font(.title2.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                    NavigationLink(value: Route.settings) {
                        Text("Settings").font(.body).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    NavigationLink(value: Route.recents) {
                        Text("Recently Viewed").font(.body).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    Text("About")
                        .font(.title2.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                    NavigationLink(value: Route.about) {
                        Text("About Accessicook").font(.body).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    NavigationLink(value: Route.privacy) {
                        Text("Privacy Policy").font(.body).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("More")
            .accessicookDestinations()
        }
    }
}
