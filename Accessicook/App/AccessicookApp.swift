import SwiftUI
import UIKit

extension CookbookStore: ObservableObject {}

@main
struct AccessicookApp: App {
    @StateObject private var favorites: FavoritesStore
    @StateObject private var recents: RecentsStore
    private let defaults: UserDefaults
    private let loaded: Result<CookbookStore, Error>

    init() {
        AccessicookApp.configureOpaqueBars()
        let defaults = AccessicookApp.makeDefaults()
        self.defaults = defaults
        _favorites = StateObject(wrappedValue: FavoritesStore(defaults: defaults))
        _recents = StateObject(wrappedValue: RecentsStore(defaults: defaults))
        loaded = Result { try CookbookStore.loadBundled() }
    }

    /// UI tests launch with -AccessicookUITesting so they start from a clean, separate store
    /// and never touch real favorites.
    private static func makeDefaults() -> UserDefaults {
        guard ProcessInfo.processInfo.arguments.contains("-AccessicookUITesting"),
              let suite = UserDefaults(suiteName: "AccessicookUITesting") else { return .standard }
        suite.removePersistentDomain(forName: "AccessicookUITesting")
        return suite
    }

    /// Opaque bars with the label color, so unselected tab and title text clears the contrast audit.
    private static func configureOpaqueBars() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        let normal = tab.stackedLayoutAppearance.normal
        normal.iconColor = .label
        normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        let selected = tab.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(red: 0.043, green: 0.227, blue: 0.431, alpha: 1)
        selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.043, green: 0.227, blue: 0.431, alpha: 1)]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigation.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
    }

    var body: some Scene {
        WindowGroup {
            switch loaded {
            case .success(let store):
                RootView()
                    .environmentObject(store)
                    .environmentObject(favorites)
                    .environmentObject(recents)
                    .defaultAppStorage(defaults)
            case .failure(let error):
                Text("Accessicook could not load its recipes. \(error.localizedDescription)")
                    .font(.body)
                    .padding()
            }
        }
    }
}

/// Applies the text size chosen in Settings, and turns off motion when Reduce Motion is on.
struct RootView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let base = ContentView()
            .transaction { transaction in
                if reduceMotion { transaction.disablesAnimations = true }
            }
        let sized: AnyView = {
            if let size = textSize.dynamicTypeSize {
                return AnyView(base.dynamicTypeSize(size))
            }
            return AnyView(base)
        }()
        if contrast == .increased {
            sized.environment(\.legibilityWeight, .bold)
        } else {
            sized
        }
    }
}
