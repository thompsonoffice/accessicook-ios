import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var store: CookbookStore
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        let recentKeys = Array(recents.keys.filter { store.title(forKey: $0) != nil }.prefix(3))
        NavigationStack {
            List {
                if let start = store.startHere {
                    Section {
                        EntryRow(entry: start)
                    } header: {
                        SectionHeader("Start here")
                    } footer: {
                        Text("A short lesson on reading Accessicook with VoiceOver or a braille display.")
                            .readableSecondary()
                    }
                }
                if !recentKeys.isEmpty {
                    Section {
                        ForEach(recentKeys, id: \.self) { key in
                            if let id = SavedKey.entryID(key), let entry = store.entry(id) {
                                EntryRow(entry: entry)
                            }
                        }
                        if recents.keys.count > recentKeys.count {
                            NavigationLink("All recently viewed (\(recents.keys.count))", value: Route.recents)
                        }
                    } header: {
                        SectionHeader("Recently Viewed")
                    }
                }
                Section {
                    ForEach(store.categories) { category in
                        let list = store.entries(in: category.id)
                        NavigationLink(value: Route.category(category.id)) {
                            LabeledCountRow(
                                title: category.name,
                                count: list.count,
                                noun: category.isLesson ? "lesson" : "recipe",
                                plural: category.isLesson ? "lessons" : "recipes"
                            )
                        }
                    }
                } header: {
                    SectionHeader("Categories")
                } footer: {
                    Text("\(store.lessonCount) lessons and \(store.recipeCount) recipes. Everything is stored in the app and works offline.")
                        .readableSecondary()
                }
            }
            .navigationTitle("Accessicook")
            .tint(Color(uiColor: .label))
            .accessicookDestinations()
        }
    }
}

struct CategoryView: View {
    let category: CookbookCategory
    @EnvironmentObject private var store: CookbookStore

    var body: some View {
        let list = store.entries(in: category.id)
        List {
            Section {
                Text(category.summary)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section {
                ForEach(list) { entry in
                    EntryRow(entry: entry)
                }
            } header: {
                SectionHeader("\(list.count) \(list.count == 1 ? (category.isLesson ? "lesson" : "recipe") : (category.isLesson ? "lessons" : "recipes"))")
            }
        }
        .navigationTitle(category.name)
        .inlineTitle()
    }
}

struct RecentsView: View {
    @EnvironmentObject private var store: CookbookStore
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        let keys = recents.keys.filter { store.title(forKey: $0) != nil }
        List {
            if keys.isEmpty {
                Text("Nothing viewed yet. Recipes and lessons you open appear here, newest first.")
                    .font(.body)
                    .readableSecondary()
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Section {
                    ForEach(keys, id: \.self) { key in
                        if let id = SavedKey.entryID(key), let entry = store.entry(id) {
                            EntryRow(entry: entry)
                                .accessibilityAction(named: Text("Remove from Recently Viewed")) {
                                    recents.remove(key)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        recents.remove(key)
                                    } label: {
                                        Label("Remove from Recently Viewed", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    SectionHeader("\(keys.count) \(keys.count == 1 ? "page" : "pages"), newest first")
                }
                Section {
                    Button("Clear Recently Viewed", role: .destructive) { recents.removeAll() }
                        .accessibilityHint("Removes every recently viewed page from this iPhone.")
                }
            }
        }
        .navigationTitle("Recently Viewed")
        .inlineTitle()
    }
}
