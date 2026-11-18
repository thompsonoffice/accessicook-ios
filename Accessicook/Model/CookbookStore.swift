import Foundation

final class CookbookStore {
    let data: CookbookData
    let categories: [CookbookCategory]
    let entries: [Entry]
    private let entryByID: [String: Entry]
    private let categoryByID: [String: CookbookCategory]
    private let searchIndex: [String: String]

    init(data: CookbookData) {
        self.data = data
        categories = data.categories.sorted { $0.sortIndex < $1.sortIndex }
        entries = data.entries
        let entriesByID = Dictionary(data.entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let categoriesByID = Dictionary(data.categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        entryByID = entriesByID
        categoryByID = categoriesByID
        var index: [String: String] = [:]
        for entry in data.entries {
            let categoryName = categoriesByID[entry.categoryID]?.name ?? entry.categoryID
            index[entry.id] = CookbookStore.fold(CookbookStore.blob(entry, categoryName: categoryName))
        }
        searchIndex = index
    }

    static func loadBundled(bundle: Bundle = Bundle(for: CookbookBundleToken.self)) throws -> CookbookStore {
        guard let url = bundle.url(forResource: "accessicook-data", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try load(url: url)
    }

    static func load(url: URL) throws -> CookbookStore {
        let raw = try Data(contentsOf: url)
        return CookbookStore(data: try JSONDecoder().decode(CookbookData.self, from: raw))
    }

    func entry(_ id: String) -> Entry? { entryByID[id] }
    func category(_ id: String) -> CookbookCategory? { categoryByID[id] }
    func categoryName(_ id: String) -> String { categoryByID[id]?.name ?? id }

    func entries(in categoryID: String) -> [Entry] {
        entries
            .filter { $0.categoryID == categoryID }
            .sorted { lhs, rhs in
                if lhs.sortIndex != rhs.sortIndex { return lhs.sortIndex < rhs.sortIndex }
                return CookbookStore.nameOrder(lhs.title, rhs.title)
            }
    }

    var recipeCount: Int { entries.filter { !$0.isLesson }.count }
    var lessonCount: Int { entries.filter(\.isLesson).count }

    /// The first Kitchen Basics lesson, used as the "start here" row.
    var startHere: Entry? {
        entries(in: "kitchen-basics").first
    }

    static func nameOrder(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }

    func title(forKey key: String) -> String? {
        guard let id = SavedKey.entryID(key) else { return nil }
        return entry(id)?.title
    }

    // MARK: Search

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                     locale: Locale(identifier: "en_US"))
    }

    /// Every word must appear. Commas and extra spaces separate words.
    static func terms(_ query: String) -> [String] {
        fold(query)
            .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" || $0 == "\t" })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    /// Full-text search. Title matches rank first. An empty query returns the category, or nothing.
    func search(_ query: String, categoryID: String? = nil) -> [Entry] {
        let words = CookbookStore.terms(query)
        let pool = entries.filter { categoryID == nil || $0.categoryID == categoryID }
        let ordered = pool.sorted { lhs, rhs in
            if lhs.categoryID == rhs.categoryID {
                if lhs.sortIndex != rhs.sortIndex { return lhs.sortIndex < rhs.sortIndex }
                return CookbookStore.nameOrder(lhs.title, rhs.title)
            }
            let left = category(lhs.categoryID)?.sortIndex ?? 0
            let right = category(rhs.categoryID)?.sortIndex ?? 0
            return left < right
        }
        guard !words.isEmpty else { return categoryID == nil ? [] : ordered }
        let hits = ordered.filter { entry in
            guard let haystack = searchIndex[entry.id] else { return false }
            return words.allSatisfy { haystack.contains($0) }
        }
        let foldedQuery = CookbookStore.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        func rank(_ entry: Entry) -> Int {
            let name = CookbookStore.fold(entry.title)
            if name == foldedQuery { return 0 }
            if name.hasPrefix(foldedQuery) { return 1 }
            if words.allSatisfy({ name.contains($0) }) { return 2 }
            return 3
        }
        return hits.enumerated().sorted { lhs, rhs in
            let left = rank(lhs.element)
            let right = rank(rhs.element)
            return left != right ? left < right : lhs.offset < rhs.offset
        }.map(\.element)
    }

    static func blob(_ entry: Entry, categoryName: String) -> String {
        var parts = [entry.title, entry.subtitle ?? "", categoryName, entry.servings ?? "",
                     entry.totalTime ?? "", entry.difficulty ?? ""]
        for section in entry.sections {
            parts.append(section.title)
            parts.append(contentsOf: section.blocks.map(\.text))
        }
        return parts.joined(separator: "\n")
    }
}
