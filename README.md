# Ritm · رتم

A native iOS 17+ daily goal and habit tracker built with **SwiftUI**, **SwiftData**, **WidgetKit**, **Swift Charts** and **UserNotifications**. It has no third-party dependencies.

Create goals across areas of life, set a target number of days, get a daily reminder, check goals off from the app or a widget, and celebrate every milestone.

## Features

- **Today:** a daily progress ring, category filters, goal cards with a one-tap check-in, streaks and reminder times.
- **Widgets:**
  - Home Screen (small, medium, large), with check-off buttons that work without opening the app.
  - Lock Screen (circular gauge, rectangular summary, inline).
- **Insights:** check-ins, completion rate, perfect days and best streak; a bar chart (week / month / year); a 17-week consistency heatmap; best weekdays; a life-area donut chart; per-goal success rates; and written insights.
- **Achievements:** 19 badges in four tiers (Bronze, Silver, Gold, Legendary), levels and points, and per-goal milestones at 25 / 50 / 75 / 100%. Each one gets a full-screen celebration (confetti, light rays, a shining medal, haptics) and a **share card** (1080×1350 image) for Messages, WhatsApp, Instagram and other apps.
- **Arabic + right-to-left:** the whole app, widgets and notifications are translated, with Arabic plural rules.
- **Reminders:** one daily notification per goal, with a "Mark as Achieved ✅" button.
- **Accounts:** a step-by-step sign-up (name, age, email, phone, password with a strength meter), log in, password reset, log out and delete account.
- **Profiles:** profile photo (cropped and compressed to about 30 KB, stored in Firestore, so no paid Firebase Storage is needed), a bio, a favorite habit, and up to 3 showcase badges.
- **Friends:** find people by exact email or phone, send and accept requests, and challenge a friend in one tap.
- **Challenges:** 1 vs 1 or group challenges with live leaderboards, a head-to-head scoreboard, and a group letter grade. When a challenge ends, a results board shows the winner on an animated podium, with confetti and a shareable image.

## Open in Xcode

```bash
brew install xcodegen
```

```bash
xcodegen generate && open Ritm.xcodeproj
```

Run `xcodegen generate` again whenever you pull changes that add or remove files.

### One-time signing setup (needed for widgets)

The app and its widgets share data through an **App Group**.

1. In `project.yml`, change `BUNDLE_ID_PREFIX: com.example` to your own, e.g. `com.yourname`. That one value sets both bundle IDs and the App Group (`group.com.yourname.Ritm`). Then run `xcodegen generate` again.
2. In Xcode, select the **Ritm** project. For **both** targets (**Ritm** and **RitmWidgets**), open **Signing & Capabilities** and choose your **Team**. A free Apple ID works.
3. Run the app (⌘R).

If the App Group isn't available, the app still works; it just keeps its data privately, and the widgets show "Open Ritm to finish setting up widgets". **Settings ▸ About ▸ Widgets** shows whether they're connected.

### Accounts, friends & challenges (Firebase, one-time setup)

Online features use **Firebase** (free plan). Until it's connected, the login screen says so, and in Debug builds you can still use the **"Developer: log in as admin (demo data)"** button. It opens a demo account with sample friends, live challenges and a finished challenge's results board. That button only exists in builds run from Xcode, never in App Store builds.

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and choose **Add project** (name it "Ritm"; Google Analytics is optional).
2. Choose **Add app ▸ iOS**. Enter your bundle ID: `BUNDLE_ID_PREFIX` + `.Ritm`, e.g. `com.yourname.Ritm`.
3. Download **GoogleService-Info.plist** and put it in the `Ritm/` folder (next to `App/`). It's git-ignored on purpose.
4. Go to **Build ▸ Authentication ▸ Get started ▸ Email/Password** and turn on **Enable**.
5. Go to **Build ▸ Firestore Database ▸ Create database**, pick **production mode** and a nearby location. Then open the **Rules** tab, paste the contents of `firestore.rules` from this repo, and choose **Publish**.
6. Run `xcodegen generate` and build. The first build downloads the Firebase package, which takes a few minutes.

**How data is stored:**
- Private details (email, phone, age) are readable only by their owner.
- Friends are found by a SHA-256 hash of the exact email or phone, so nobody can browse other users' contact details.
- Personal goals stay on the device in SwiftData. Only friends and challenges are online.

### Add the widgets (Simulator or iPhone)

1. Go to the Home Screen (⇧⌘H in the Simulator) and long-press an empty area.
2. Tap **Edit ▸ Add Widget**, then search for **Ritm**.
3. For Lock Screen widgets, lock the device (⌘L), long-press the Lock Screen, then tap **Customize ▸ Lock Screen** and add a Ritm widget.

### Try the app in Arabic

- **On a device or the Simulator:** go to **Settings ▸ Apps ▸ Ritm ▸ Language ▸ العربية**. The in-app **Settings ▸ App Language** row takes you there.
- **From Xcode, without changing the device:** choose **Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Options ▸ App Language ▸ Arabic**.

## Structure

```
Shared/                 Compiled into both the app and the widget extension
├── Models/             Goal, DailyLog, AchievementRecord (@Model), GoalCategory, GoalSnapshot, date & streak math
├── Persistence/        SharedStore: App Group SwiftData container + cross-process change signal
├── Intents/            ToggleGoalIntent: the interactive widget button
└── Resources/          Localizable.xcstrings (English + Arabic)
Ritm/
├── App/                RitmApp, RootView (tabs + celebration layer)
├── Models/             Achievement & GoalMilestone definitions, GoalTemplate
├── ViewModels/         TodayViewModel, GoalFormModel, InsightsReport
├── Views/              Today, Add/Edit, Detail, History, Archived, Insights, Achievements, Celebration, Settings,
│                       Auth/ (login & sign-up), Challenges/ (list, create, detail, results), Friends/
├── Components/         Cards, rings, badges, confetti, share card, chips…
├── Managers/           NotificationManager, CelebrationCenter, ProgressAnalytics, DataStore, SessionStore, PreviewData
│   └── Backend/        SocialBackend protocol, FirebaseBackend, DemoBackend (developer admin login)
└── Resources/          Assets (app icon, رتم wordmark)
RitmWidgets/            Home Screen and Lock Screen widgets
```

## Design notes

- **Date safety.** Every `DailyLog.date` is stored as `Calendar.current.startOfDay(for:)`. Streaks walk back one calendar day at a time. If today isn't checked off yet, the streak counted through yesterday still stands.
- **Widgets and the app share one store.** Widget buttons run `ToggleGoalIntent` in the widget's process and set a "changed" timestamp in the App Group. When the app returns to the foreground it reloads its container, then checks for new achievements, so a widget check-in still earns its celebration.
- **Achievements are permanent.** Earned badges and milestones are saved as `AchievementRecord`s, so undoing a check-in never takes one away. The first time the app runs with existing data, it records past progress silently rather than celebrating everything at once.
- **Perfect day.** Every active goal is achieved on the same day, with at least two goals. A goal stops counting once its challenge is finished.
- **Localization.** All UI text goes through `Localizable.xcstrings`. Day and point counts use Arabic plural forms (zero, one, two, few, many, other). Layout direction, numbers and dates follow the selected language automatically.
