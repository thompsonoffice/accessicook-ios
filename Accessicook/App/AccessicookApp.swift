import SwiftUI

extension CookbookStore: ObservableObject {}

@main
struct AccessicookApp: App {
    @StateObject private var favorites: FavoritesStore
    @StateObject private var recents: RecentsStore
    private let defaults: UserDefaults
    private let loaded: Result<CookbookStore, Error>

    init() {
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
