import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var query = ""
    @State private var categoryID = SearchView.allCategories
    @State private var announceTask: Task<Void, Never>?

    private static let allCategories = "all"

    private var selectedCategory: String? { categoryID == SearchView.allCategories ? nil : categoryID }
    private var isIdle: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedCategory == nil
    }

    var body: some View {
        let results = isIdle ? [] : store.search(query, categoryID: selectedCategory)
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $categoryID) {
                        Text("All categories").tag(SearchView.allCategories)
                        ForEach(store.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .accessibilityHint("Limits results to one category, or searches the whole book.")
                } header: {
                    SectionHeader("Category")
                }
                if isIdle {
                    Text("Search recipes and lessons. Every word you type must appear. For example: pancakes, omelette, thermometer, or sautéed peppers.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .readableSecondary()
                } else if results.isEmpty {
                    Text("No results. Try fewer words, or choose All categories.")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("resultCount")
                } else {
                    Section {
                        Text(results.count == 1 ? "1 result" : "\(results.count) results")
                            .font(.body)
                            .accessibilityIdentifier("resultCount")
                    } header: {
                        SectionHeader("Results")
                    }
                    Section {
                        ForEach(results) { entry in
                            EntryRow(entry: entry)
                        }
                    }
                }
            }
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .navigationTitle("Search")
            .accessicookDestinations()
            .onChange(of: query) { _, _ in announceCount() }
            .onChange(of: categoryID) { _, _ in announceCount() }
        }
    }

    /// Speaks the result count once typing pauses, so VoiceOver users hear it without leaving the field.
    private func announceCount() {
        announceTask?.cancel()
        guard !isIdle else { return }
        let query = query
        let categoryID = selectedCategory
        announceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            let count = store.search(query, categoryID: categoryID).count
            AccessibilityNotification.Announcement(count == 1 ? "1 result" : "\(count) results").post()
        }
    }
}
