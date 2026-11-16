import SwiftUI

/// Text size choices. "Use iPhone setting" follows Settings, Accessibility, Display and Text Size.
enum TextSizeOption: String, CaseIterable, Identifiable {
    case system, xSmall, small, medium, large, xLarge, xxLarge, xxxLarge,
         accessibility1, accessibility2, accessibility3, accessibility4, accessibility5

    static let storageKey = "accessicook.textSize"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Use iPhone setting"
        case .xSmall: return "Extra small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (iPhone default)"
        case .xLarge: return "Extra large"
        case .xxLarge: return "Extra extra large"
        case .xxxLarge: return "Extra extra extra large"
        case .accessibility1: return "Accessibility size 1"
        case .accessibility2: return "Accessibility size 2"
        case .accessibility3: return "Accessibility size 3"
        case .accessibility4: return "Accessibility size 4"
        case .accessibility5: return "Accessibility size 5, largest"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: return nil
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        case .accessibility1: return .accessibility1
        case .accessibility2: return .accessibility2
        case .accessibility3: return .accessibility3
        case .accessibility4: return .accessibility4
        case .accessibility5: return .accessibility5
        }
    }
}

struct SettingsView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var recents: RecentsStore
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmFavorites = false

    var body: some View {
        Form {
            Section {
                NavigationLink(value: Route.textSize) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Text size")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color(uiColor: .label))
                        Text(textSize.title)
                            .font(.body)
                            .foregroundStyle(Color(uiColor: .label))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
                Text("Sample: Heat the oven to 425 degrees F, then bake until the center feels set.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Text size sample. Heat the oven to 425 degrees F, then bake until the center feels set.")
            } header: {
                SectionHeader("Text")
            } footer: {
                Text("Every screen uses Dynamic Type. Use iPhone setting follows Settings, Accessibility, Display and Text Size. This includes the largest accessibility sizes.")
                    .readableSecondary()
            }

            Section {
                LabeledStatus(title: "Increase Contrast",
                              value: contrast == .increased ? "On" : "Off, using the iPhone setting")
                LabeledStatus(title: "Reduce Motion",
                              value: reduceMotion ? "On" : "Off, using the iPhone setting")
            } header: {
                SectionHeader("Display")
            } footer: {
                Text("Accessicook follows Increase Contrast, Bold Text, Reduce Motion, Differentiate Without Color, and Dark Mode from iPhone Settings. It does not replace those switches.")
                    .readableSecondary()
            }

            Section {
                if recents.keys.isEmpty && favorites.keys.isEmpty {
                    Text("Nothing is saved yet.")
                        .font(.body)
                        .readableSecondary()
                }
                if !recents.keys.isEmpty {
                    Button("Clear Recently Viewed (\(recents.keys.count))", role: .destructive) { recents.removeAll() }
                }
                if !favorites.keys.isEmpty {
                    Button("Remove All Favorites (\(favorites.keys.count))", role: .destructive) { confirmFavorites = true }
                }
            } header: {
                SectionHeader("Saved on This iPhone")
            } footer: {
                Text("Favorites, recently viewed pages, and the text size setting stay on this iPhone. Nothing is sent anywhere.")
                    .readableSecondary()
            }
        }
        .navigationTitle("Settings")
        .inlineTitle()
        .confirmationDialog("Remove all \(favorites.keys.count) favorites?",
                            isPresented: $confirmFavorites,
                            titleVisibility: .visible) {
            Button("Remove All Favorites", role: .destructive) { favorites.removeAll() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Each size is its own button, so VoiceOver and the UI tests can choose one directly.
struct TextSizePickerView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(TextSizeOption.allCases) { option in
                Button {
                    textSize = option
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(option.title)
                            .font(.body)
                            .foregroundStyle(Color(uiColor: .label))
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if textSize == option {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                }
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(textSize == option ? .isSelected : [])
            }
        }
        .navigationTitle("Text size")
        .inlineTitle()
    }
}

struct LabeledStatus: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.body.weight(.semibold))
            Text(value)
                .font(.body)
                .readableSecondary()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
