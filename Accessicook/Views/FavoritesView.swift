import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: CookbookStore
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        let saved = favorites.keys.compactMap { key -> Entry? in
            guard let id = SavedKey.entryID(key) else { return nil }
            return store.entry(id)
        }.sorted { CookbookStore.nameOrder($0.title, $1.title) }
        NavigationStack {
            List {
                if saved.isEmpty {
                    Text("No favorites yet. Open a recipe or lesson and choose Favorite. Favorites stay on this iPhone.")
                        .font(.body)
                        .readableSecondary()
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Section {
                        ForEach(saved) { entry in
                            EntryRow(entry: entry)
                                .accessibilityAction(named: Text("Remove from Favorites")) {
                                    favorites.remove(SavedKey.recipe(entry.id))
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        favorites.remove(SavedKey.recipe(entry.id))
                                    } label: {
                                        Label("Remove from Favorites", systemImage: "star.slash")
                                    }
                                }
                        }
                    } header: {
                        SectionHeader("\(saved.count) \(saved.count == 1 ? "favorite" : "favorites")")
                    }
                }
                Section {
                    NavigationLink(value: Route.recents) {
                        Text("Recently Viewed")
                            .font(.body)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                } header: {
                    SectionHeader("Also on this iPhone")
                }
            }
            .navigationTitle("Favorites")
            .accessicookDestinations()
        }
    }
}
