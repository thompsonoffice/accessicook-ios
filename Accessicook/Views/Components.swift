import SwiftUI

extension View {
    func accessicookDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteView(route: route)
        }
    }

    func inlineTitle() -> some View {
        navigationBarTitleDisplayMode(.inline)
    }
}

struct RouteView: View {
    let route: Route
    @EnvironmentObject private var store: CookbookStore

    var body: some View {
        switch route {
        case .category(let id):
            if let category = store.category(id) {
                CategoryView(category: category)
            } else {
                MissingEntryView()
            }
        case .entry(let id):
            if let entry = store.entry(id) {
                RecipeDetailView(entry: entry)
            } else {
                MissingEntryView()
            }
        case .cook(let id):
            if let entry = store.entry(id) {
                CookModeView(entry: entry)
            } else {
                MissingEntryView()
            }
        case .recents:
            RecentsView()
        case .settings:
            SettingsView()
        case .textSize:
            TextSizePickerView()
        case .about:
            AboutView()
        case .privacy:
            PrivacyPolicyView()
        }
    }
}

struct MissingEntryView: View {
    var body: some View {
        Text("This page is not in Accessicook.")
            .font(.body)
            .padding()
    }
}

/// Supporting text uses the label color so it stays above the contrast minimum in light and dark mode.
struct ReadableSecondary: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.foregroundStyle(scheme == .dark ? Color.white : Color.black)
    }
}

extension View {
    func readableSecondary() -> some View { modifier(ReadableSecondary()) }
}

struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) private var scheme
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            .accessibilityAddTraits(.isHeader)
            .textCase(nil)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BodyText: View {
    let text: String
    @Environment(\.colorScheme) private var scheme
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 1)
            .background(scheme == .dark ? Color.black : Color.white)
    }
}

struct FavoriteMark: View {
    var body: some View {
        Image(systemName: "star.fill")
            .imageScale(.small)
            .accessibilityLabel("Favorite")
    }
}

struct FavoriteButton: View {
    let entry: Entry
    @EnvironmentObject private var favorites: FavoritesStore

    private var key: String { SavedKey.recipe(entry.id) }

    var body: some View {
        let isOn = favorites.contains(key)
        Button {
            favorites.toggle(key)
            let message = isOn
                ? "Removed \(entry.title) from Favorites."
                : "Added \(entry.title) to Favorites."
            AccessibilityNotification.Announcement(message).post()
        } label: {
            Label(isOn ? "Favorite, saved" : "Favorite", systemImage: isOn ? "star.fill" : "star")
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityLabel("Favorite")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .buttonStyle(.plain)
        .highContrastFill()
        .accessibilityHint(isOn
                           ? "Removes \(entry.title) from Favorites."
                           : "Adds \(entry.title) to Favorites. Saved on this iPhone only.")
        .accessibilityIdentifier("favoriteButton")
    }
}

struct ShareTextButton: View {
    let entry: Entry
    let categoryName: String

    var body: some View {
        let text = TextExporter.text(for: entry, categoryName: categoryName)
        ShareLink(item: TextFileExport(fileName: TextExporter.fileName(entry.title), text: text),
                  preview: SharePreview("\(entry.title), plain text")) {
            Label("Share as Text", systemImage: "square.and.arrow.up")
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .highContrastFill()
        .accessibilityHint("Shares or saves this page as a plain text file.")
    }
}

/// A list row read as one VoiceOver element, for example "Pancakes, Breakfast, Beginner, About 25 minutes, Favorite".
struct EntryRow: View {
    let entry: Entry
    @EnvironmentObject private var store: CookbookStore
    @EnvironmentObject private var favorites: FavoritesStore
    @Environment(\.colorScheme) private var scheme

    private var ink: Color { scheme == .dark ? Color.white : Color.black }

    var body: some View {
        NavigationLink(value: Route.entry(entry.id)) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if favorites.contains(SavedKey.recipe(entry.id)) {
                        FavoriteMark()
                    }
                }
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
        .tint(ink)
    }

    private var subtitle: String {
        let category = store.categoryName(entry.categoryID)
        if entry.isLesson {
            return "\(category) lesson"
        }
        let time = firstLine(entry.totalTime) ?? "Time not listed"
        let difficulty = firstLine(entry.difficulty) ?? "Difficulty not listed"
        return "\(category), \(difficulty), \(time)"
    }

    private func firstLine(_ text: String?) -> String? {
        text?.split(whereSeparator: \.isNewline).first.map(String.init)
    }
}

struct LabeledCountRow: View {
    let title: String
    let count: Int
    let noun: String
    let plural: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text("\(title), \(count) \(count == 1 ? noun : plural)")
            .font(.body.weight(.semibold))
            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

struct BlockStack: View {
    let blocks: [Block]
    var stepPrefix: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder private func blockView(_ block: Block) -> some View {
        switch block.kind {
        case "bullet":
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\u{2022}")
                    .accessibilityHidden(true)
                BodyText(block.text)
            }
            .accessibilityElement(children: .combine)
        case "step", "numbered":
            let number = block.number ?? 0
            BodyText("\(number). \(block.text)")
                .accessibilityLabel(stepPrefix ? "Step \(number). \(block.text)" : "\(number). \(block.text)")
        default:
            if isSubheading(block.text) {
                Text(block.text)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            } else if let url = standaloneURL(block.text) {
                Link(destination: url) {
                    Text(linkLabel(url))
                        .font(.body)
                        .foregroundStyle(Color(uiColor: .label))
                        .underline()
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .accessibilityHint("Opens in your web browser. This is a source citation, not a store.")
            } else {
                BodyText(block.text)
            }
        }
    }

    private func isSubheading(_ text: String) -> Bool {
        text.count <= 80 && !text.contains(". ") && !text.hasSuffix(".")
    }

    private func standaloneURL(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("https://") || trimmed.hasPrefix("http://"),
              !trimmed.contains(where: \.isWhitespace),
              let url = URL(string: trimmed),
              url.host != nil else { return nil }
        return url
    }

    private func linkLabel(_ url: URL) -> String {
        let host = url.host ?? url.absoluteString
        return "Source link, \(host)"
    }
}

/// Filled control: background-colored words on the label color, which clears the contrast audit in both appearances.
struct HighContrastFill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color(uiColor: .systemBackground))
            .background(Color(uiColor: .label))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func highContrastFill() -> some View { modifier(HighContrastFill()) }
}

/// Full-width control used in cooking mode. The words are the VoiceOver label. Icons are hidden.
struct LargeTextButton: View {
    let title: String
    let systemImage: String
    var hint: String = ""
    var identifier: String = ""
    /// Filled buttons use the dark accent color with white text. Outlined buttons use primary text.
    var prominent: Bool = true
    let action: () -> Void

    var body: some View {
        let button = Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundStyle(prominent ? Color(uiColor: .systemBackground) : Color(uiColor: .label))
            .background(prominent ? Color(uiColor: .label) : Color(uiColor: .systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(uiColor: .label), lineWidth: prominent ? 0 : 3)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)

        styled(button)
    }

    @ViewBuilder private func styled<V: View>(_ view: V) -> some View {
        if hint.isEmpty {
            view
        } else {
            view.accessibilityHint(hint)
        }
    }
}
