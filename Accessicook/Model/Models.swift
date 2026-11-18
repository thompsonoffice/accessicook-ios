import Foundation

struct CookbookData: Codable, Hashable {
    var version: Int
    var title: String
    var honestNotes: [String]
    var categories: [CookbookCategory]
    var entries: [Entry]
}

struct CookbookCategory: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var kind: String
    var summary: String
    var sortIndex: Int

    var isLesson: Bool { kind == "lesson" }
}

struct Entry: Codable, Identifiable, Hashable {
    var id: String
    var categoryID: String
    var title: String
    var subtitle: String?
    var fileName: String
    var sortIndex: Int
    var kind: String
    var servings: String?
    var totalTime: String?
    var difficulty: String?
    var sections: [RecipeSection]

    var isLesson: Bool { kind == "lesson" }
    var noun: String { isLesson ? "lesson" : "recipe" }
}

/// One headed block of a recipe or lesson. Named so it does not shadow SwiftUI.Section.
struct RecipeSection: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var isSteps: Bool
    var blocks: [Block]
}

struct Block: Codable, Hashable {
    var kind: String
    var text: String
    var number: Int?

    var isStep: Bool { kind == "step" }
}

/// One cooking method inside a step section. Bacon has four (skillet and oven, pork and turkey).
/// Most recipes have one method titled "Steps".
struct CookMethod: Identifiable, Hashable {
    var id: String
    var title: String
    var steps: [CookStep]
}

struct CookStep: Identifiable, Hashable {
    var id: String
    var number: Int
    var text: String
    var timer: StepTimerCue?
}

enum Route: Hashable {
    case category(String)
    case entry(String)
    case cook(String)
    case recents
    case settings
    case textSize
    case about
    case privacy
}

enum SavedKey {
    static func recipe(_ id: String) -> String { "recipe:" + id }

    static func entryID(_ key: String) -> String? {
        guard key.hasPrefix("recipe:") else { return nil }
        return String(key.dropFirst(7))
    }
}

extension Optional where Wrapped == String {
    var nonEmpty: String? {
        switch self {
        case .some(let value) where !value.isEmpty: return value
        default: return nil
        }
    }
}

/// NSObject so Bundle(for:) finds the app bundle that holds the JSON.
final class CookbookBundleToken: NSObject {}
