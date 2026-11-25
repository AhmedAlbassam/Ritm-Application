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
├── Views/              Today, Add/Edit, Detail, History, Archived, Insights, Achievements, Celebration, Settings
├── Components/         Cards, rings, badges, confetti, share card, chips…
├── Managers/           NotificationManager, CelebrationCenter, ProgressAnalytics, DataStore, PreviewData
└── Resources/          Assets (app icon, رتم wordmark)
RitmWidgets/            Home Screen and Lock Screen widgets
```

## Design notes

- **Date safety.** Every `DailyLog.date` is stored as `Calendar.current.startOfDay(for:)`. Streaks walk back one calendar day at a time. If today isn't checked off yet, the streak counted through yesterday still stands.
- **Widgets and the app share one store.** Widget buttons run `ToggleGoalIntent` in the widget's process and set a "changed" timestamp in the App Group. When the app returns to the foreground it reloads its container, then checks for new achievements, so a widget check-in still earns its celebration.
- **Achievements are permanent.** Earned badges and milestones are saved as `AchievementRecord`s, so undoing a check-in never takes one away. The first time the app runs with existing data, it records past progress silently rather than celebrating everything at once.
- **Perfect day.** Every active goal is achieved on the same day, with at least two goals. A goal stops counting once its challenge is finished.
- **Localization.** All UI text goes through `Localizable.xcstrings`. Day and point counts use Arabic plural forms (zero, one, two, few, many, other). Layout direction, numbers and dates follow the selected language automatically.
