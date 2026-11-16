import Foundation

struct PolicySection: Identifiable, Hashable {
    let heading: String
    let body: String
    var id: String { heading }
    init(_ heading: String, _ body: String) {
        self.heading = heading
        self.body = body
    }
}

/// The in-app privacy policy. docs/PRIVACY-POLICY.md has the same text for the web page
/// App Store Connect asks for. Keep the two in sync.
enum PrivacyPolicy {
    static let effectiveDate = "November 16, 2026"
    static let paragraphs: [PolicySection] = [
        PolicySection("Summary", "Accessicook does not collect, store, share, or sell any personal information. The developer, Hunter Thompson, receives no data from the app."),
        PolicySection("Works offline", "Every recipe and lesson is included in the app. Accessicook makes no network requests of its own and works with no internet connection."),
        PolicySection("No accounts, ads, or tracking", "There are no accounts, sign-ins, analytics, advertising, tracking, or third-party software development kits. Accessicook is a paid app. You buy it on the App Store. The app has no other purchases and no links to buy it somewhere else."),
        PolicySection("What stays on your device", "Your favorites, recently viewed recipes, and text size setting are saved only on your own device, in the app's local settings. They are never sent to the developer or anyone else. Deleting the app deletes them. They may be included in your own device backups, which Apple handles under its privacy policy."),
        PolicySection("Links and sharing", "When you choose a source link in a recipe, it opens in your web browser and that website's own privacy policy applies. Source links are citations, not a store. When you choose Share as Text, the text goes only where you send it."),
        PolicySection("Children", "Accessicook collects no data from anyone, including children."),
        PolicySection("Changes", "If this policy ever changes, the new version will appear in the app and on its web page with a new effective date."),
    ]
}
