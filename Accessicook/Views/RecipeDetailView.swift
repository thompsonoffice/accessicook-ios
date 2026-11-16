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
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                        .foregroundStyle(Color.white)
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
        }
        .navigationTitle(entry.isLesson ? "Lesson" : "Recipe")
        .inlineTitle()
        .onAppear { recents.record(SavedKey.recipe(entry.id)) }
    }

    private func summary(categoryName: String) -> String {
        if entry.isLesson { return "\(categoryName) lesson" }
        var parts = [categoryName]
        if let difficulty = firstLine(entry.difficulty) { parts.append(difficulty) }
        if let time = firstLine(entry.totalTime) { parts.append(time) }
        if let servings = firstLine(entry.servings) { parts.append(servings) }
        return parts.joined(separator: ". ")
    }

    private func firstLine(_ text: String?) -> String? {
        guard let text else { return nil }
        return text.split(whereSeparator: \.isNewline).first.map(String.init)
    }
}
