import SwiftUI
import UIKit

/// One step at a time, with large buttons. VoiceOver is told the step each time it changes.
struct CookModeView: View {
    let entry: Entry
    @State private var methodID: String?
    private var methods: [CookMethod] { CookPlan.methods(for: entry) }

    var body: some View {
        Group {
            if methods.isEmpty {
                Text("This page has no numbered cooking steps.")
                    .font(.body)
                    .padding()
            } else if methods.count > 1, methodID == nil {
                MethodChooser(entry: entry, methods: methods) { methodID = $0 }
            } else if let method = (methods.first(where: { $0.id == methodID }) ?? methods.first) {
                CookStepsView(entry: entry, method: method, canChangeMethod: methods.count > 1) {
                    methodID = nil
                }
            }
        }
        .navigationTitle("Cooking")
        .inlineTitle()
    }
}

private struct MethodChooser: View {
    let entry: Entry
    let methods: [CookMethod]
    let choose: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Choose a method")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(entry.title) has \(methods.count) ways to cook. Pick one. You can switch later.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(methods) { method in
                    LargeTextButton(
                        title: "\(method.title). \(method.steps.count) steps",
                        systemImage: "list.number",
                        hint: "Opens these steps one at a time.",
                        identifier: "methodButton"
                    ) {
                        choose(method.id)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            AccessibilityNotification.Announcement("\(entry.title). Choose a method. \(methods.count) methods.").post()
        }
    }
}

private struct CookStepsView: View {
    let entry: Entry
    let method: CookMethod
    let canChangeMethod: Bool
    let changeMethod: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timer = CookingTimer()
    @State private var index = 0

    private var step: CookStep { method.steps[index] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.title)
                    .font(.title2.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if method.title != "Steps" {
                    Text(method.title)
                        .font(.title3)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                Text("Step \(index + 1) of \(method.steps.count)")
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("stepPosition")
                    .accessibilityAddTraits(.isHeader)

                Text(step.text)
                    .font(.title2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("cookStep")
                    .accessibilityLabel("Step \(step.number). \(step.text)")
                    .accessibilityAction(named: Text("Next step")) { next() }
                    .accessibilityAction(named: Text("Previous step")) { previous() }

                timerControls

                if index > 0 {
                    LargeTextButton(
                        title: "Previous step",
                        systemImage: "chevron.backward",
                        hint: "Goes back one step.",
                        identifier: "previousStep",
                        prominent: false
                    ) { previous() }
                }
                if index + 1 < method.steps.count {
                    LargeTextButton(
                        title: "Next step",
                        systemImage: "chevron.forward",
                        hint: "Goes to step \(index + 2) of \(method.steps.count).",
                        identifier: "nextStep"
                    ) { next() }
                } else {
                    LargeTextButton(
                        title: "Done",
                        systemImage: "checkmark",
                        hint: "Leaves cooking and returns to the recipe.",
                        identifier: "doneCooking"
                    ) {
                        AccessibilityNotification.Announcement("Finished \(entry.title). Back to the recipe.").post()
                        dismiss()
                    }
                }
                if canChangeMethod {
                    LargeTextButton(
                        title: "Choose another method",
                        systemImage: "arrow.triangle.branch",
                        hint: "Returns to the list of methods for \(entry.title).",
                        identifier: "changeMethod",
                        prominent: false
                    ) {
                        timer.cancel()
                        changeMethod()
                    }
                }
            }
            .padding()
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(index)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            announceStep(canceledTimer: false)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timer.cancel()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { timer.tick() }
        }
        .onChange(of: timer.didFinish) { _, finished in
            if finished {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                AccessibilityNotification.Announcement("Timer finished.").post()
            }
        }
        .animation(reduceMotion ? nil : .default, value: index)
    }

    @ViewBuilder private var timerControls: some View {
        if timer.didFinish {
            Text("Timer finished.")
                .font(.title.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("timerStatus")
                .accessibilityAddTraits(.isHeader)
            if let cue = step.timer {
                LargeTextButton(
                    title: "Start timer again",
                    systemImage: "timer",
                    hint: cue.hint,
                    identifier: "startTimer"
                ) {
                    timer.start(seconds: cue.seconds)
                    AccessibilityNotification.Announcement("Timer started for \(cue.lengthDescription).").post()
                }
            }
            LargeTextButton(
                title: "Dismiss timer",
                systemImage: "xmark",
                hint: "Clears the finished timer.",
                identifier: "cancelTimer",
                prominent: false
            ) {
                timer.cancel()
                AccessibilityNotification.Announcement("Timer dismissed.").post()
            }
        } else if let remaining = timer.remainingSeconds {
            Text(StepTimerParser.clock(remaining))
                .font(.largeTitle.monospacedDigit().weight(.bold))
                .accessibilityLabel("Time remaining, \(StepTimerParser.spokenRemaining(remaining)).")
                .accessibilityIdentifier("timerStatus")
            Text(timer.isRunning ? "Timer running" : "Timer paused")
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
            if timer.isRunning {
                LargeTextButton(
                    title: "Pause timer",
                    systemImage: "pause.fill",
                    hint: "Pauses the countdown.",
                    identifier: "pauseTimer"
                ) {
                    timer.pause()
                    let left = timer.remainingSeconds ?? 0
                    AccessibilityNotification.Announcement("Timer paused. \(StepTimerParser.spokenRemaining(left)) left.").post()
                }
            } else {
                LargeTextButton(
                    title: "Resume timer",
                    systemImage: "play.fill",
                    hint: "Continues the countdown.",
                    identifier: "resumeTimer"
                ) {
                    timer.resume()
                    let left = timer.remainingSeconds ?? 0
                    AccessibilityNotification.Announcement("Timer resumed. \(StepTimerParser.spokenRemaining(left)) left.").post()
                }
            }
            LargeTextButton(
                title: "Add one minute",
                systemImage: "plus",
                hint: "Adds 60 seconds.",
                identifier: "addMinute",
                prominent: false
            ) {
                timer.addMinute()
                let left = timer.remainingSeconds ?? 0
                AccessibilityNotification.Announcement("Added one minute. \(StepTimerParser.spokenRemaining(left)) left.").post()
            }
            LargeTextButton(
                title: "Cancel timer",
                systemImage: "xmark",
                hint: "Stops the timer without finishing.",
                identifier: "cancelTimer",
                prominent: false
            ) {
                timer.cancel()
                AccessibilityNotification.Announcement("Timer canceled.").post()
            }
        } else if let cue = step.timer {
            LargeTextButton(
                title: cue.buttonTitle,
                systemImage: "timer",
                hint: cue.hint,
                identifier: "startTimer"
            ) {
                timer.start(seconds: cue.seconds)
                AccessibilityNotification.Announcement("Timer started for \(cue.lengthDescription).").post()
            }
        }
    }

    private func next() {
        guard index + 1 < method.steps.count else { return }
        move(to: index + 1)
    }

    private func previous() {
        guard index > 0 else { return }
        move(to: index - 1)
    }

    private func move(to newIndex: Int) {
        let canceled = timer.remainingSeconds != nil
        if canceled { timer.cancel() }
        index = newIndex
        announceStep(canceledTimer: canceled)
    }

    private func announceStep(canceledTimer: Bool) {
        var message = canceledTimer ? "Timer canceled. " : ""
        message += "\(entry.title). Step \(index + 1) of \(method.steps.count). \(step.text)"
        if step.timer != nil {
            message += " A timer is available for this step."
        }
        AccessibilityNotification.Announcement(message).post()
    }
}
