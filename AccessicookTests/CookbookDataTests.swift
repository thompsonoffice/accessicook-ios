import XCTest
@testable import Accessicook

final class CookbookDataTests: XCTestCase {
    private static let shared: CookbookStore = {
        try! CookbookStore.loadBundled()
    }()
    private var store: CookbookStore { Self.shared }

    func testBundledCountsMatchTheBook() {
        XCTAssertEqual(store.data.title, "Accessicook")
        XCTAssertEqual(store.data.version, 1)
        XCTAssertEqual(store.lessonCount, 13)
        XCTAssertEqual(store.recipeCount, 327)
        XCTAssertEqual(store.entries.count, 340)
        XCTAssertEqual(store.categories.map(\.name), [
            "Kitchen Basics", "Breakfast", "Lunch", "Supper", "Baked Goods", "Midnight Snacks", "Misc"
        ])
        XCTAssertEqual(store.entries(in: "breakfast").count, 40)
        XCTAssertEqual(store.entries(in: "lunch").count, 55)
        XCTAssertEqual(store.entries(in: "supper").count, 73)
        XCTAssertEqual(store.entries(in: "baked-goods").count, 58)
        XCTAssertEqual(store.entries(in: "midnight-snacks").count, 36)
        XCTAssertEqual(store.entries(in: "misc").count, 65)
        XCTAssertEqual(store.entries(in: "kitchen-basics").count, 13)
    }

    func testIDsAreUniqueAndResolve() {
        XCTAssertEqual(Set(store.entries.map(\.id)).count, store.entries.count)
        for entry in store.entries {
            XCTAssertNotNil(store.category(entry.categoryID), entry.id)
            XCTAssertFalse(entry.title.isEmpty, entry.id)
            XCTAssertFalse(entry.sections.isEmpty, entry.id)
            XCTAssertEqual(entry.sections.first?.title, "Introduction", entry.id)
        }
    }

    func testRecipesKeepTheBookHeadingOrder() {
        let pancakes = try! XCTUnwrap(store.entry("breakfast/pancakes"))
        XCTAssertEqual(pancakes.sections.map(\.title), [
            "Introduction", "Servings", "Total Time", "Difficulty", "Equipment", "Ingredients",
            "Tactile Tips", "Before You Start", "Steps", "How to Tell When It Is Done",
            "For the Sighted Helper", "Safety", "Tips and Variations", "Leftovers", "Sources"
        ])
        XCTAssertEqual(pancakes.sections.first { $0.isSteps }?.blocks.filter(\.isStep).count, 12)
        XCTAssertTrue(pancakes.sections.contains { $0.title == "Ingredients" })
    }

    func testLessonsAreNotCookingSteps() throws {
        let lesson = try XCTUnwrap(store.entry("kitchen-basics/how-to-use-this-book"))
        XCTAssertTrue(lesson.isLesson)
        XCTAssertTrue(CookPlan.methods(for: lesson).isEmpty)
        XCTAssertTrue(lesson.sections.contains { $0.blocks.contains { $0.kind == "numbered" } })
        XCTAssertEqual(store.startHere?.id, lesson.id)
    }

    func testBaconHasFourMethodsThatRestartAtOne() throws {
        let bacon = try XCTUnwrap(store.entry("breakfast/bacon"))
        XCTAssertEqual(bacon.subtitle, "Regular Pork Bacon and Turkey Bacon")
        let methods = CookPlan.methods(for: bacon)
        XCTAssertEqual(methods.count, 4)
        XCTAssertTrue(methods.contains { $0.title.contains("Skillet method (pork)") })
        XCTAssertTrue(methods.contains { $0.title.contains("Oven method (turkey)") })
        for method in methods {
            XCTAssertEqual(method.steps.map(\.number), Array(1...method.steps.count), method.title)
            XCTAssertFalse(method.steps.contains { $0.text.isEmpty })
        }
    }

    func testNoInventedOrDeepFryRecipesAndNoStoreLinks() {
        let titles = store.entries.map { $0.title.lowercased() }
        XCTAssertFalse(titles.contains { $0.contains("deep fry") || $0.contains("deep-fry") || $0.contains("deep-fried") })
        let blob = store.entries.map { CookbookStore.blob($0, categoryName: store.categoryName($0.categoryID)) }.joined(separator: "\n")
        XCTAssertFalse(blob.lowercased().contains("itch.io"))
        XCTAssertTrue(blob.contains("Do not deep-fry"))
    }

    func testHonestNotesArePresent() {
        let notes = store.data.honestNotes.joined(separator: " ")
        XCTAssertTrue(notes.contains("not been individually kitchen-tested"))
        XCTAssertTrue(notes.contains("Deep frying is left out on purpose"))
        XCTAssertTrue(notes.contains("not been formally screen-reader tested"))
    }

    // MARK: Search

    func testSearchRanksTheExactTitleFirst() {
        let results = store.search("rice")
        XCTAssertEqual(results.first?.title, "Rice")
        XCTAssertTrue(results.contains { $0.title == "Rice Pilaf" })
    }

    func testSearchIsCaseAndAccentInsensitive() {
        XCTAssertEqual(store.search("omelette").map(\.id), store.search("OMELETTE").map(\.id))
        XCTAssertEqual(CookbookStore.fold("sautéed"), "sauteed")
        XCTAssertTrue(store.search("sauteed peppers").contains { $0.id == "lunch/quesadillas" })
    }

    func testSearchRequiresEveryWord() {
        let both = store.search("blueberry pancakes")
        XCTAssertEqual(both.first?.id, "breakfast/pancakes")
        XCTAssertTrue(store.search("zzzz-not-a-recipe qqqq").isEmpty)
        XCTAssertTrue(store.search("   ").isEmpty)
    }

    func testSearchCategoryFilter() {
        let breakfast = store.search("", categoryID: "breakfast")
        XCTAssertEqual(breakfast.count, 40)
        XCTAssertTrue(breakfast.allSatisfy { $0.categoryID == "breakfast" })
        let filtered = store.search("egg", categoryID: "breakfast")
        XCTAssertFalse(filtered.isEmpty)
        XCTAssertTrue(filtered.allSatisfy { $0.categoryID == "breakfast" })
    }

    func testSavedKeyRoundTrip() {
        XCTAssertEqual(SavedKey.entryID(SavedKey.recipe("breakfast/pancakes")), "breakfast/pancakes")
        XCTAssertNil(SavedKey.entryID("bogus"))
        XCTAssertEqual(store.title(forKey: SavedKey.recipe("breakfast/pancakes")), "Pancakes")
        XCTAssertNil(store.title(forKey: SavedKey.recipe("missing")))
    }

    func testTextExportContainsTheSections() throws {
        let pancakes = try XCTUnwrap(store.entry("breakfast/pancakes"))
        let text = TextExporter.text(for: pancakes, categoryName: "Breakfast")
        XCTAssertTrue(text.hasPrefix("Pancakes\n"))
        for heading in ["INTRODUCTION", "INGREDIENTS", "STEPS", "SAFETY", "SOURCES"] {
            XCTAssertTrue(text.contains(heading), heading)
        }
        XCTAssertTrue(text.contains("1. Mix the flour, sugar, baking powder, and salt in a bowl."))
        XCTAssertEqual(TextExporter.fileName("Pancakes"), "Pancakes.txt")
        XCTAssertEqual(TextExporter.fileName("A/B: C?"), "A-B- C.txt")
        XCTAssertEqual(TextExporter.fileName("   "), "Recipe.txt")
    }

    func testPrivacyManifestDeclaresNoCollection() throws {
        let bundle = Bundle(for: CookbookBundleToken.self)
        let url = try XCTUnwrap(bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("<key>NSPrivacyTracking</key>"))
        XCTAssertTrue(text.contains("<false/>"))
        XCTAssertTrue(text.contains("<key>NSPrivacyCollectedDataTypes</key>"))
        XCTAssertTrue(text.contains("NSPrivacyAccessedAPICategoryUserDefaults"))
        XCTAssertTrue(text.contains("CA92.1"))
        XCTAssertFalse(text.contains("NSPrivacyCollectedDataTypePurpose"))
        XCTAssertTrue(text.contains("<key>NSPrivacyTrackingDomains</key>"))
        let policy = PrivacyPolicy.paragraphs.map { $0.heading + $0.body }.joined()
        XCTAssertTrue(policy.contains("does not collect"))
        XCTAssertFalse(policy.contains("itch.io"))
        XCTAssertFalse(policy.contains("["))
    }
}
