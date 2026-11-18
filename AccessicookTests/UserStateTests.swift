import XCTest
@testable import Accessicook

final class UserStateTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "AccessicookTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testFavoritesToggleAndPersist() {
        let favorites = FavoritesStore(defaults: defaults)
        favorites.toggle(SavedKey.recipe("breakfast/pancakes"))
        favorites.toggle(SavedKey.recipe("lunch/blt"))
        XCTAssertTrue(favorites.contains(SavedKey.recipe("breakfast/pancakes")))
        favorites.toggle(SavedKey.recipe("breakfast/pancakes"))
        XCTAssertFalse(favorites.contains(SavedKey.recipe("breakfast/pancakes")))
        XCTAssertEqual(FavoritesStore(defaults: defaults).keys, [SavedKey.recipe("lunch/blt")])
        favorites.removeAll()
        XCTAssertTrue(FavoritesStore(defaults: defaults).keys.isEmpty)
    }

    func testRecentsNewestFirstWithoutDuplicates() {
        let recents = RecentsStore(defaults: defaults)
        recents.record("recipe:a")
        recents.record("recipe:b")
        recents.record("recipe:a")
        XCTAssertEqual(recents.keys, ["recipe:a", "recipe:b"])
        XCTAssertEqual(RecentsStore(defaults: defaults).keys, ["recipe:a", "recipe:b"])
        recents.remove("recipe:a")
        XCTAssertEqual(RecentsStore(defaults: defaults).keys, ["recipe:b"])
    }

    func testRecentsAreCapped() {
        let recents = RecentsStore(defaults: defaults)
        for index in 0..<(RecentsStore.limit + 10) {
            recents.record("recipe:\(index)")
        }
        XCTAssertEqual(recents.keys.count, RecentsStore.limit)
        XCTAssertEqual(recents.keys.first, "recipe:\(RecentsStore.limit + 9)")
    }

    func testTextSizeOptionsCoverTheAccessibilitySizes() {
        XCTAssertNil(TextSizeOption.system.dynamicTypeSize)
        XCTAssertEqual(TextSizeOption.accessibility5.dynamicTypeSize, .accessibility5)
        XCTAssertEqual(TextSizeOption.large.dynamicTypeSize, .large)
        XCTAssertEqual(TextSizeOption.allCases.count, 13)
    }
}
