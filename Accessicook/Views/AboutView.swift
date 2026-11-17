import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var store: CookbookStore

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About Accessicook")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                DetailSection("What this is") {
                    BodyText("Accessicook is a cookbook for blind and low-vision cooks, and for the people who cook alongside them. Every recipe uses the same headings, one action per numbered step, and measurements written so a screen reader can say them.")
                    BodyText("Doneness is described with sound, smell, texture, time, and a thermometer first. Visual cues are there for a sighted helper to say out loud.")
                    BodyText("The book works offline. There are no accounts, no ads, and no tracking.")
                }
                DetailSection("Honest notes") {
                    ForEach(store.data.honestNotes, id: \.self) { note in
                        if note.contains("kitchen-tested") {
                            BodyText(note)
                                .accessibilityIdentifier("honestyNote")
                        } else {
                            BodyText(note)
                        }
                    }
                }
                DetailSection("What is included") {
                    LabeledFact(label: "Lessons", value: "\(store.lessonCount) Kitchen Basics lessons")
                    LabeledFact(label: "Recipes", value: "\(store.recipeCount) recipes in 6 categories")
                    LabeledFact(label: "Categories", value: store.categories.map(\.name).joined(separator: ", "))
                }
                DetailSection("How to cook from the app") {
                    BodyText("Browse by category, or search. Open a recipe and use the headings rotor to jump to Ingredients or Steps. Cook step by step reads one step at a time, with large Next and Previous buttons, and can start a timer when a step gives a time.")
                    BodyText("Favorite and Recently Viewed are saved on this iPhone only.")
                }
                DetailSection("Privacy") {
                    BodyText("Accessicook collects no data. It is a paid app. The price is $3.99 on the App Store. There is nothing else to buy inside the app, and no link to buy it somewhere else.")
                    NavigationLink("Read the privacy policy", value: Route.privacy)
                        .frame(minHeight: 44, alignment: .leading)
                }
                LabeledFact(label: "Developer", value: "Hunter Thompson")
                LabeledFact(label: "Version", value: version)
            }
            .padding()
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("About")
        .inlineTitle()
    }
}

struct LabeledFact: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(uiColor: .label))
            Text(value)
                .font(.body)
                .foregroundStyle(Color(uiColor: .label))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Accessicook Privacy Policy")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                BodyText("Effective \(PrivacyPolicy.effectiveDate)")
                ForEach(PrivacyPolicy.paragraphs) { item in
                    DetailSection(item.heading) { BodyText(item.body) }
                }
            }
            .padding()
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Privacy Policy")
        .inlineTitle()
    }
}
