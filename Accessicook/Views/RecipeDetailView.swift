import SwiftUI

struct RecipeDetailView: View {
    let entry: Entry
    @EnvironmentObject private var store: CookbookStore
    @EnvironmentObject private var recents: RecentsStore

    private var methods: [CookMethod] { CookPlan.methods(for: entry) }

    var body: some View {
        let categoryName = store.categoryName(entry.categoryID)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle = entry.subtitle.nonEmpty {
                        Text(subtitle)
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(summary(categoryName: categoryName))
                        .font(.body)
                        .readableSecondary()
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    FavoriteButton(entry: entry)
                    if !methods.isEmpty {
                        NavigationLink(value: Route.cook(entry.id)) {
                            HStack(spacing: 12) {
                                Image(systemName: "list.number")
                                    .accessibilityHidden(true)
                                Text("Cook step by step")
                                    .font(.title3.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .highContrastFill()
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Reads \(entry.title) one step at a time, with large Next and Previous buttons.")
                        .accessibilityIdentifier("cookButton")
                    }
                    ShareTextButton(entry: entry, categoryName: categoryName)
                }

                ForEach(entry.sections) { section in
                    DetailSection(section.title) {
                        BlockStack(blocks: section.blocks, stepPrefix: section.isSteps)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("")
        .inlineTitle()
        .onAppear { recents.record(SavedKey.recipe(entry.id)) }
    }

    private func summary(categoryName: String) -> String {
        if entry.isLesson { return "\(categoryName) lesson" }
        var parts = [categoryName]
        if let difficulty = shortFact(entry.difficulty) { parts.append(difficulty) }
        if let time = shortFact(entry.totalTime) { parts.append(time) }
        return parts.joined(separator: ". ")
    }

    /// The first sentence, kept short so the page opens on the headings instead of a repeated essay.
    private func shortFact(_ text: String?) -> String? {
        guard let text else { return nil }
        guard let line = text.split(whereSeparator: \.isNewline).first else { return nil }
        let sentence = line.split(separator: ".").first.map(String.init) ?? String(line)
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 80 else { return nil }
        return trimmed
    }
}
