import XCTest
import UIKit

/// Captures App Store screenshots of the real app (Guideline 2.3.3).
/// Lives on the app-store-screenshots branch only. Does not change app behavior.
final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("screens").path
        outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-AccessicookUITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        settle()
    }

    func testCaptureAppStoreScreenshots() throws {
        tab("Browse")
        XCTAssertTrue(app.staticTexts["Categories"].waitForExistence(timeout: 15))
        try capture("01-browse")

        tapRow("Breakfast")
        try capture("02-breakfast")

        tapRow("Omelette")
        XCTAssertTrue(app.staticTexts["Ingredients"].waitForExistence(timeout: 10))
        try capture("03-recipe")
        app.buttons["Favorite"].tap()
        settle()

        tab("Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("chicken")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        dismissKeyboard()
        try capture("04-search")

        field.tap()
        if let value = field.value as? String, !value.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        field.typeText("Pancakes")
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        dismissKeyboard()
        tapRow("Pancakes")
        let cook = app.buttons["Cook step by step"]
        XCTAssertTrue(cook.waitForExistence(timeout: 10))
        cook.tap()
        let next = app.buttons["nextStep"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        next.tap(); next.tap(); next.tap()
        let start = app.buttons["startTimer"]
        if start.waitForExistence(timeout: 5) { start.tap() }
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        try capture("05-cook-mode")
        if app.buttons["cancelTimer"].exists { app.buttons["cancelTimer"].tap() }

        tab("Favorites")
        try capture("06-favorites")
    }

    // MARK: - Capture

    private func capture(_ name: String) throws {
        settle()
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "\(prefix)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        let url = outputDirectory.appendingPathComponent("\(prefix)-\(name).png")
        try shot.pngRepresentation.write(to: url)
        print("Wrote \(url.path)")
    }

    private var prefix: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
    }

    private func tab(_ name: String) {
        let bar = app.tabBars.buttons[name]
        if bar.waitForExistence(timeout: 8) {
            bar.tap()
        } else {
            let any = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch
            XCTAssertTrue(any.waitForExistence(timeout: 5), "tab \(name)")
            any.tap()
        }
        settle()
    }

    private func rowCandidates(_ p: String) -> [XCUIElement] {
        let pred = NSPredicate(format: "label BEGINSWITH %@", p)
        return [app.buttons.matching(pred).firstMatch, app.cells.matching(pred).firstMatch]
    }

    private func tapRow(_ p: String) {
        let deadline = Date().addingTimeInterval(6)
        var element = rowCandidates(p).first(where: \.exists)
        while element == nil && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            element = rowCandidates(p).first(where: \.exists)
        }
        var swipes = 0
        while element?.isHittable != true && swipes < 20 {
            app.swipeUp()
            swipes += 1
            element = rowCandidates(p).first(where: \.exists)
        }
        XCTAssertTrue(element?.exists == true, "row starting with \(p)")
        element?.tap()
        settle()
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        settle()
    }

    private func scrollToTop() {
        for _ in 0..<4 { app.swipeDown() }
    }

    private func dismissKeyboard() {
        for key in ["Search", "search", "Done"] where app.keyboards.buttons[key].exists {
            app.keyboards.buttons[key].tap()
            return
        }
    }

    private func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
    }
}
