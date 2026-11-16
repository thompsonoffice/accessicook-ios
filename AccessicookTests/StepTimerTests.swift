import XCTest
@testable import Accessicook

final class StepTimerTests: XCTestCase {
    func testParsesASingleDuration() {
        let cue = StepTimerParser.parse(from: "Let the batter rest 5 minutes. Rest means let it sit.")
        XCTAssertEqual(cue?.seconds, 300)
        XCTAssertEqual(cue?.shortLength, "5 minutes")
        XCTAssertEqual(cue?.buttonTitle, "Start timer for 5 minutes")
        XCTAssertEqual(cue?.lengthDescription, "5 minutes")
    }

    func testRangeUsesTheLongerEnd() {
        let cue = StepTimerParser.parse(from: "Cook until the edges feel set, about 2 to 3 minutes.")
        XCTAssertEqual(cue?.seconds, 180)
        XCTAssertEqual(cue?.shortLength, "3 minutes")
        XCTAssertEqual(cue?.lengthDescription, "3 minutes, the longer end of 2 to 3 minutes")
    }

    func testIgnoresTemperaturesAndVagueTimes() {
        XCTAssertNil(StepTimerParser.parse(from: "Heat the oven to 425 degrees F."))
        XCTAssertNil(StepTimerParser.parse(from: "Cook eggs until the yolk and white are firm, 160 degrees F."))
        XCTAssertNil(StepTimerParser.parse(from: "Turn the slices every couple of minutes."))
        XCTAssertNil(StepTimerParser.parse(from: "Within a minute or so, it will feel thicker."))
        XCTAssertNil(StepTimerParser.parse(from: "Eat refrigerated leftovers within 3 to 4 days."))
        XCTAssertNil(StepTimerParser.parse(from: "Mix the flour, sugar, baking powder, and salt in a bowl."))
    }

    func testUnitsAndSingular() {
        XCTAssertEqual(StepTimerParser.parse(from: "Wait 30 seconds.")?.seconds, 30)
        XCTAssertEqual(StepTimerParser.parse(from: "Bake 1 hour.")?.shortLength, "1 hour")
        XCTAssertEqual(StepTimerParser.parse(from: "Chill 2 hours.")?.seconds, 7200)
        XCTAssertEqual(StepTimerParser.parse(from: "Rest 1 minute.")?.shortLength, "1 minute")
    }

    func testSpokenRemainingAndClock() {
        XCTAssertEqual(StepTimerParser.spokenRemaining(300), "5 minutes")
        XCTAssertEqual(StepTimerParser.spokenRemaining(252), "4 minutes and 12 seconds")
        XCTAssertEqual(StepTimerParser.spokenRemaining(3661), "1 hour and 1 minute and 1 second")
        XCTAssertEqual(StepTimerParser.spokenRemaining(0), "0 seconds")
        XCTAssertEqual(StepTimerParser.clock(300), "5:00")
        XCTAssertEqual(StepTimerParser.clock(3661), "1:01:01")
    }

    func testPancakesStepFourOffersFiveMinutes() throws {
        let store = try CookbookStore.loadBundled()
        let pancakes = try XCTUnwrap(store.entry("breakfast/pancakes"))
        let steps = try XCTUnwrap(CookPlan.methods(for: pancakes).first?.steps)
        XCTAssertNil(steps[0].timer)
        XCTAssertEqual(steps[3].timer?.seconds, 300)
        XCTAssertTrue(steps[3].text.hasPrefix("Let the batter rest 5 minutes"))
        XCTAssertEqual(steps[8].timer?.seconds, 180)
        XCTAssertEqual(steps[10].timer?.seconds, 120)
    }

    func testCountdownUsesTheEndDate() {
        let timer = CookingTimer()
        let start = Date(timeIntervalSince1970: 1_000)
        timer.start(seconds: 90, now: start, armTicker: false)
        XCTAssertTrue(timer.isRunning)
        timer.tick(now: start.addingTimeInterval(30), armTicker: false)
        XCTAssertEqual(timer.remainingSeconds, 60)
        timer.pause(now: start.addingTimeInterval(40))
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds, 50)
        timer.resume(now: start.addingTimeInterval(100), armTicker: false)
        timer.tick(now: start.addingTimeInterval(150), armTicker: false)
        XCTAssertTrue(timer.didFinish)
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    func testAddMinuteAndCancel() {
        let timer = CookingTimer()
        let start = Date(timeIntervalSince1970: 5_000)
        timer.start(seconds: 10, now: start, armTicker: false)
        timer.addMinute(now: start, armTicker: false)
        timer.tick(now: start.addingTimeInterval(10), armTicker: false)
        XCTAssertEqual(timer.remainingSeconds, 60)
        XCTAssertFalse(timer.didFinish)
        timer.cancel()
        XCTAssertNil(timer.remainingSeconds)
        XCTAssertFalse(timer.isRunning)
    }
}
