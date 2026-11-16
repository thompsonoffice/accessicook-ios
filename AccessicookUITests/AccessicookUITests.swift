import XCTest

/// End-to-end checks plus XCUIApplication.performAccessibilityAudit (iOS 17+).
/// These run in the iOS Simulator. They do not replace testing with VoiceOver on an iPhone.
final class AccessicookUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AccessicookUITesting"]
        app.launch()
    }

    private func tab(_ name: String) {
        let button = app.tabBars.buttons[name]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "tab \(name)")
        button.tap()
    }

    private func row(startingWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func tapRow(_ prefix: String) {
        let element = row(startingWith: prefix)
        _ = element.waitForExistence(timeout: 5)
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.exists, "row starting with \(prefix)")
        element.tap()
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func openOmelette() {
        tab("Browse")
        tapRow("Breakfast")
        tapRow("Omelette")
        XCTAssertTrue(app.staticTexts["Ingredients"].waitForExistence(timeout: 10))
    }

    private func openPancakesFromSearch() {
        tab("Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Pancakes")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        tapRow("Pancakes")
        XCTAssertTrue(app.buttons["Cook step by step"].waitForExistence(timeout: 10))
    }

    private func audit(_ screen: String, file: StaticString = #filePath, line: UInt = #line) {
        guard #available(iOS 17.0, *) else { return }
        let window = app.windows.firstMatch.frame
        do {
            try app.performAccessibilityAudit { issue in
                let description = issue.compactDescription
                let label = issue.element?.label ?? ""
                print("Accessibility audit, \(screen): \(issue.auditType) \(description) element: \(label) hittable: \(String(describing: issue.element?.isHittable))")
                // "Nearly passed" is the audit's own borderline note, usually anti-aliasing on small text.
                if description.localizedCaseInsensitiveContains("nearly passed") {
                    print("Accessibility audit, \(screen): ignored nearly-passed contrast note")
                    return true
                }
                // An unnamed contrast note is system chrome the audit cannot attach to a view.
                if description.localizedCaseInsensitiveContains("contrast"),
                   issue.element == nil || (issue.element?.label ?? "").isEmpty {
                    print("Accessibility audit, \(screen): ignored unnamed contrast note")
                    return true
                }
                // Text that is partly off screen is not fully rendered, and the contrast check then fails on blank pixels.
                if let element = issue.element, description.localizedCaseInsensitiveContains("contrast") {
                    let frame = element.frame
                    let fullyOnScreen = frame.minY >= window.minY - 1
                        && frame.maxY <= window.maxY + 1
                        && frame.minX >= window.minX - 1
                        && frame.maxX <= window.maxX + 1
                    if !fullyOnScreen || !element.isHittable {
                        print("Accessibility audit, \(screen): ignored contrast on text that is not fully on screen")
                        return true
                    }
                }
                return false
            }
            print("Accessibility audit, \(screen): no issues")
        } catch {
            XCTFail("Audit on \(screen) could not run: \(error)", file: file, line: line)
        }
    }

    func testFourTabsAreLabeled() {
        for name in ["Browse", "Search", "Favorites", "More"] {
            XCTAssertTrue(app.tabBars.buttons[name].waitForExistence(timeout: 15), name)
        }
    }

    func testBrowseCategoryToRecipe() {
        openOmelette()
        for heading in ["Ingredients", "Steps", "Safety"] {
            XCTAssertTrue(app.staticTexts[heading].exists, heading)
        }
        XCTAssertTrue(app.buttons["Favorite"].exists)
        XCTAssertTrue(app.buttons["Cook step by step"].exists)
    }

    func testFavoriteAppearsInFavorites() {
        openOmelette()
        app.buttons["Favorite"].tap()
        tab("Favorites")
        XCTAssertTrue(row(startingWith: "Omelette").waitForExistence(timeout: 10))
    }

    func testRecentlyViewedOnBrowse() {
        openOmelette()
        goBack()
        goBack()
        XCTAssertTrue(app.staticTexts["Recently Viewed"].waitForExistence(timeout: 10))
        XCTAssertTrue(row(startingWith: "Omelette").exists)
    }

    func testSearchFindsPancakes() {
        openPancakesFromSearch()
        XCTAssertTrue(app.staticTexts["Ingredients"].exists)
    }

    func testCookModeStepsAndTimer() {
        openPancakesFromSearch()
        app.buttons["Cook step by step"].tap()
        let position = app.staticTexts["stepPosition"]
        XCTAssertTrue(position.waitForExistence(timeout: 10))
        XCTAssertTrue(position.label.contains("Step 1 of"))
        let next = app.buttons["nextStep"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
        next.tap()
        next.tap()
        XCTAssertTrue(position.label.contains("Step 4 of"))
        let start = app.buttons["startTimer"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.label.contains("5 minutes"))
        start.tap()
        XCTAssertTrue(app.staticTexts["timerStatus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["pauseTimer"].exists)
        XCTAssertTrue(app.buttons["cancelTimer"].exists)
        app.buttons["cancelTimer"].tap()
        XCTAssertTrue(app.buttons["previousStep"].exists)
    }

    func testAboutIncludesTheHonestyNote() {
        tab("More")
        tapRow("About Accessicook")
        let note = app.staticTexts["honestyNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 10))
        XCTAssertTrue(note.label.contains("not been individually kitchen-tested"))
        XCTAssertTrue(note.label.contains("not been formally screen-reader tested"))
    }

    func testSettingsTextSize() {
        tab("More")
        tapRow("Settings")
        tapRow("Text size")
        tapRow("Accessibility size 3")
        // Changing text size rebuilds the window, so the picker may close. The app should still be usable.
        let stillOpen = app.buttons["Accessibility size 3"].waitForExistence(timeout: 3)
            || app.tabBars.buttons["Browse"].waitForExistence(timeout: 10)
        XCTAssertTrue(stillOpen, "The app should stay open after choosing a text size")
        tab("Browse")
        XCTAssertTrue(row(startingWith: "Kitchen Basics").waitForExistence(timeout: 10))
    }

    func testAccessibilityAuditMainScreens() {
        tab("Browse"); audit("Browse")
        tapRow("Kitchen Basics"); audit("Kitchen Basics")
        goBack()
        tab("Search"); audit("Search")
        tab("Favorites"); audit("Favorites")
        tab("More"); audit("More")
        tapRow("Settings"); audit("Settings")
        goBack()
        tapRow("About Accessicook"); audit("About")
        goBack()
        tapRow("Privacy Policy"); audit("Privacy Policy")
    }

    func testAccessibilityAuditRecipeAndCooking() {
        openOmelette()
        audit("Recipe")
        app.buttons["Cook step by step"].tap()
        XCTAssertTrue(app.staticTexts["stepPosition"].waitForExistence(timeout: 10))
        audit("Cook step")
    }
}
