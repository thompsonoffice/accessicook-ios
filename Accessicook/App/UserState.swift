import Foundation
import Combine

/// Favorites saved in UserDefaults on this device only.
/// Keys look like "recipe:breakfast/pancakes".
final class FavoritesStore: ObservableObject {
    static let storageKey = "accessicook.favorites"
    @Published private(set) var keys: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        keys = defaults.stringArray(forKey: FavoritesStore.storageKey) ?? []
    }

    func contains(_ key: String) -> Bool { keys.contains(key) }

    func toggle(_ key: String) {
        if let index = keys.firstIndex(of: key) { keys.remove(at: index) } else { keys.append(key) }
        save()
    }

    func remove(_ key: String) {
        keys.removeAll { $0 == key }
        save()
    }

    func removeAll() {
        keys = []
        save()
    }

    private func save() { defaults.set(keys, forKey: FavoritesStore.storageKey) }
}

/// Recently viewed recipes and lessons, newest first, saved on this device only.
final class RecentsStore: ObservableObject {
    static let storageKey = "accessicook.recents"
    static let limit = 25
    @Published private(set) var keys: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        keys = defaults.stringArray(forKey: RecentsStore.storageKey) ?? []
    }

    /// Moves the entry to the top. Opening the same recipe again does not add a duplicate.
    func record(_ key: String) {
        if keys.first == key { return }
        keys.removeAll { $0 == key }
        keys.insert(key, at: 0)
        if keys.count > RecentsStore.limit { keys.removeLast(keys.count - RecentsStore.limit) }
        save()
    }

    func remove(_ key: String) {
        keys.removeAll { $0 == key }
        save()
    }

    func removeAll() {
        keys = []
        save()
    }

    private func save() { defaults.set(keys, forKey: RecentsStore.storageKey) }
}
