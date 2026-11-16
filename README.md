# Accessicook for iPhone

A native SwiftUI iPhone app (iOS 17+) of Accessicook, a cookbook for blind and low-vision cooks. Fully offline, VoiceOver-first, no data collection.

- Content: 13 Kitchen Basics lessons and 327 recipes in six categories (Breakfast, Lunch, Supper, Baked Goods, Midnight Snacks, and Misc), converted from the plain-text book in `content/Accessicook` by `tools/export_cookbook.py`.
- Planned listing: App Store, paid (price set later), category Food & Drink, privacy label **Data Not Collected**. The app does not link out to sell itself, and it has no ads or tracking.

## Features

- **Browse** by category, with Kitchen Basics lessons and a Start here lesson.
- **Full-text search** across titles, ingredients, steps, and the rest of each page. Every word must match. Case and accents are ignored. A title match ranks first. The result count is spoken after typing pauses.
- **Favorites** and **recently viewed** (last 25), saved on the device only.
- **Recipe reader** with the book's headings in the book's order, marked so the VoiceOver headings rotor can jump to Ingredients, Steps, Safety, and the rest.
- **Cook step by step** reads one step at a time, with large Next and Previous buttons, and speaks each step. Bacon offers its skillet and oven methods separately.
- **Timer** on a step that states a time, such as "5 minutes" or "10 to 20 minutes". A range uses the longer end. The timer is optional and runs while the app is open.
- **Settings** for text size (the iPhone setting, or any of 12 Dynamic Type sizes up to Accessibility 5). Increase Contrast, Bold Text, Reduce Motion, Differentiate Without Color, and Dark Mode follow the iPhone settings.
- **Share as Text**, an About screen with the book's honesty note, and the privacy policy.

## Accessibility

- Section titles carry the VoiceOver heading trait.
- List rows are one element, for example "Pancakes, Breakfast, Beginner, About 25 minutes".
- Controls have text labels. Favorite reports Selected. Cooking controls are full-width buttons, not icon-only.
- Text uses Dynamic Type styles and wraps at large sizes.
- Reduce Motion turns off the step-change animation. Increase Contrast uses primary text and a heavier button border.
- The screen stays awake during cooking mode.

## Honest notes

The recipes have not been individually kitchen-tested, and the files have not been formally screen-reader tested. Deep frying is left out on purpose. The app does not add recipes.

## Project layout

- `project.yml`: XcodeGen spec (app, unit tests, UI tests). CI runs `xcodegen generate`. The generated `.xcodeproj` is not committed.
- `Accessicook/`: app sources (`App`, `Model`, `Views`), `Resources/accessicook-data.json`, a placeholder icon, and `PrivacyInfo.xcprivacy` (no data collected).
- `AccessicookTests/`: data integrity, search, cooking methods, timers, export, and saved state.
- `AccessicookUITests/`: the main flows and `performAccessibilityAudit()`.
- `.github/workflows/ios-ci.yml`: simulator build and all tests on every pull request and on pushes to `main`. No signing.
- `.github/workflows/testflight-upload.yml`: signing and upload, **skipped** until App Store Connect secrets exist. See `docs/APP-STORE-SETUP.md`.
- `docs/PRIVACY-POLICY.md`: privacy policy text for the App Store privacy policy URL.

## Local build

```bash
brew install xcodegen
python3 tools/export_cookbook.py
xcodegen generate
open Accessicook.xcodeproj
```

## Not verified yet

Real-device VoiceOver use, signing, TestFlight, and App Review have not happened. The simulator audit catches many problems but does not replace testing with VoiceOver on an iPhone.
