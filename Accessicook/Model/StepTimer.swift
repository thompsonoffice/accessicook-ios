import Foundation

/// A duration found in a step, such as "5 minutes" or "10 to 20 minutes".
/// A range uses the longer end so the timer does not finish early.
struct StepTimerCue: Equatable, Hashable {
    var seconds: Int
    /// "5 minutes" or "20 minutes".
    var shortLength: String
    /// Spoken description, including the range when there is one.
    var lengthDescription: String

    var buttonTitle: String { "Start timer for \(shortLength)" }

    var hint: String {
        "Starts a timer for \(lengthDescription). The timer keeps running while Accessicook is open, including if you lock the screen and come back."
    }
}

enum StepTimerParser {
    private static let pattern = try! NSRegularExpression(
        pattern: #"(\d+)\s+to\s+(\d+)\s+(seconds?|minutes?|hours?)\b|(\d+)\s+(seconds?|minutes?|hours?)\b"#,
        options: [.caseInsensitive]
    )

    static func parse(from text: String) -> StepTimerCue? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = pattern.firstMatch(in: text, options: [], range: range) else { return nil }
        if match.range(at: 1).location != NSNotFound {
            let low = number(in: text, match: match, group: 1)
            let high = number(in: text, match: match, group: 2)
            let unit = word(in: text, match: match, group: 3)
            let longer = max(low, high)
            let shorter = min(low, high)
            let shortLength = phrase(count: longer, unit: unit)
            let description = "\(shortLength), the longer end of \(shorter) to \(phrase(count: longer, unit: unit))"
            return StepTimerCue(seconds: seconds(count: longer, unit: unit),
                                 shortLength: shortLength,
                                 lengthDescription: description)
        }
        let count = number(in: text, match: match, group: 4)
        let unit = word(in: text, match: match, group: 5)
        let shortLength = phrase(count: count, unit: unit)
        return StepTimerCue(seconds: seconds(count: count, unit: unit),
                             shortLength: shortLength,
                             lengthDescription: shortLength)
    }

    private static func number(in text: String, match: NSTextCheckingResult, group: Int) -> Int {
        Int(word(in: text, match: match, group: group)) ?? 0
    }

    private static func word(in text: String, match: NSTextCheckingResult, group: Int) -> String {
        guard let range = Range(match.range(at: group), in: text) else { return "" }
        return String(text[range])
    }

    private static func unitSeconds(_ unit: String) -> Int {
        let lower = unit.lowercased()
        if lower.hasPrefix("h") { return 3600 }
        if lower.hasPrefix("m") { return 60 }
        return 1
    }

    private static func seconds(count: Int, unit: String) -> Int {
        count * unitSeconds(unit)
    }

    static func phrase(count: Int, unit: String) -> String {
        let lower = unit.lowercased()
        let name: String
        if lower.hasPrefix("h") { name = "hour" }
        else if lower.hasPrefix("m") { name = "minute" }
        else { name = "second" }
        return count == 1 ? "1 \(name)" : "\(count) \(name)s"
    }

    /// "4 minutes and 12 seconds" for a countdown.
    static func spokenRemaining(_ total: Int) -> String {
        let seconds = max(0, total)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        var parts: [String] = []
        if hours > 0 { parts.append(phrase(count: hours, unit: "hours")) }
        if minutes > 0 { parts.append(phrase(count: minutes, unit: "minutes")) }
        if remainder > 0 || parts.isEmpty { parts.append(phrase(count: remainder, unit: "seconds")) }
        return parts.joined(separator: " and ")
    }

    static func clock(_ total: Int) -> String {
        let seconds = max(0, total)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainder)
        }
        return String(format: "%d:%02d", minutes, remainder)
    }
}

enum CookPlan {
    /// Cooking methods in book order. Lessons and pages without numbered steps return an empty list.
    static func methods(for entry: Entry) -> [CookMethod] {
        entry.sections.filter(\.isSteps).flatMap { methods(in: $0) }
    }

    static func methods(in section: Section) -> [CookMethod] {
        var result: [CookMethod] = []
        var title = section.title
        var steps: [CookStep] = []
        var sawStep = false
        var paragraphs: [String] = []

        func close() {
            guard !steps.isEmpty else { return }
            result.append(CookMethod(id: "\(section.id)#\(result.count)", title: title, steps: steps))
            steps = []
        }

        for block in section.blocks {
            if block.kind == "step" {
                if !paragraphs.isEmpty {
                    let name = paragraphs.last ?? section.title
                    if sawStep {
                        close()
                    }
                    if isMethodHeading(name) {
                        title = "\(section.title), \(name)"
                    } else if !sawStep {
                        title = section.title
                    }
                    paragraphs = []
                }
                sawStep = true
                let number = block.number ?? (steps.count + 1)
                steps.append(CookStep(
                    id: "\(section.id)#\(result.count)#\(steps.count)",
                    number: number,
                    text: block.text,
                    timer: StepTimerParser.parse(from: block.text)
                ))
            } else {
                paragraphs.append(block.text)
            }
        }
        close()
        return result
    }

    /// A short line such as "Skillet method (pork)", not a full sentence.
    private static func isMethodHeading(_ text: String) -> Bool {
        text.count <= 80 && !text.contains(". ") && !text.hasSuffix(".")
    }
}

/// In-app countdown. Time is measured from an end date so a locked screen does not lose time.
/// Call it from the main thread. The ticker is scheduled on the main run loop.
final class CookingTimer: ObservableObject {
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var isRunning = false
    @Published private(set) var didFinish = false

    private var end: Date?
    private var ticker: Timer?

    var isActive: Bool { remainingSeconds != nil && !didFinish }

    func start(seconds: Int, now: Date = Date(), armTicker: Bool = true) {
        stopTicker()
        remainingSeconds = max(0, seconds)
        didFinish = seconds <= 0
        isRunning = seconds > 0
        end = seconds > 0 ? now.addingTimeInterval(TimeInterval(seconds)) : nil
        if armTicker && isRunning { startTicker() }
        if seconds <= 0 { didFinish = true; isRunning = false }
    }

    func pause(now: Date = Date()) {
        guard isRunning else { return }
        tick(now: now, armTicker: false)
        isRunning = false
        end = nil
        stopTicker()
    }

    func resume(now: Date = Date(), armTicker: Bool = true) {
        guard let remainingSeconds, !isRunning, !didFinish else { return }
        end = now.addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        if armTicker { startTicker() }
    }

    func addMinute(now: Date = Date(), armTicker: Bool = true) {
        if didFinish {
            start(seconds: 60, now: now, armTicker: armTicker)
            return
        }
        guard remainingSeconds != nil else { return }
        if isRunning, let end {
            self.end = end.addingTimeInterval(60)
        }
        remainingSeconds = (remainingSeconds ?? 0) + 60
    }

    func cancel() {
        stopTicker()
        end = nil
        isRunning = false
        didFinish = false
        remainingSeconds = nil
    }

    func tick(now: Date = Date(), armTicker: Bool = true) {
        guard isRunning, let end else { return }
        let left = Int(ceil(end.timeIntervalSince(now)))
        if left <= 0 {
            remainingSeconds = 0
            isRunning = false
            didFinish = true
            self.end = nil
            stopTicker()
        } else {
            remainingSeconds = left
            if armTicker && ticker == nil { startTicker() }
        }
    }

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    deinit {
        ticker?.invalidate()
    }
}
