# Ritm

A native iOS 17+ daily goal and habit tracker built with **SwiftUI**, **SwiftData** and **UserNotifications**. It has no third-party dependencies.

Create goals across areas of life, set a target number of days, get a daily reminder, and check each goal off with one tap.

## Open in Xcode

**Option A: XcodeGen (recommended)**

```bash
brew install xcodegen
```

```bash
xcodegen generate && open Ritm.xcodeproj
```

**Option B: by hand**

1. In Xcode, choose File ▸ New ▸ Project ▸ iOS App. Set Interface to SwiftUI and Storage to None, then name it `Ritm`.
2. Set the deployment target to iOS 17.0.
3. Delete the template's `ContentView.swift`, `RitmApp.swift` and `Assets.xcassets`.
4. Drag the `Ritm/` folders (`App`, `Models`, `ViewModels`, `Views`, `Components`, `Managers`, `Resources`) into the project with "Create groups" selected.

Local notifications don't need an Info.plist entry or a special capability.

## Structure

```
Ritm/
├── App/            RitmApp: sets up the ModelContainer and notification delegate
├── Models/         Goal, DailyLog (@Model), GoalCategory, GoalTemplate, date helpers
├── ViewModels/     TodayViewModel, GoalFormModel (@Observable)
├── Views/          TodayView, AddEditGoalView, GoalDetailView, HistoryGridView, ArchivedGoalsView
├── Components/     GoalCardView, DailySummaryCard, CategoryFilterBar, CheckInButton,
│                   ProgressRing / LinearProgressBar, badges, chips, DayCell, EmptyStateView…
└── Managers/       NotificationManager, PreviewData (DEBUG only)
```

## Design notes

- **Date safety.** Every `DailyLog.date` is stored as `Calendar.current.startOfDay(for:)`. Lookups use `isDate(_:inSameDayAs:)` and the completed-day set is normalized again when it's read. Streaks walk back one calendar day at a time. If today isn't checked off yet, the streak counted through yesterday still stands.
- **Category storage.** `Goal.category` is a computed `GoalCategory` backed by `categoryRawValue: String`, which keeps it usable in `#Predicate`.
- **Challenge model.** A challenge is complete after `targetDays` achieved days. The days don't have to be consecutive. The history grid covers the planned window and keeps growing if you run past the planned end date. You can tap any past day to backfill it. Future days are disabled.
- **Notifications.** Each goal gets one repeating `UNCalendarNotificationTrigger` (hour and minute) with the identifier `goal-reminder-<uuid>`. Saving always replaces it. Archiving, deleting or finishing the challenge removes it. At launch, `syncReminders` re-schedules active reminders and removes any left over. Permission is requested in context, when the reminder toggle is first switched on. If it's denied, an alert links to Settings. Each reminder has a **"Mark as Achieved ✅"** action that logs today's check-in without opening the app.
- **Day rollover.** The Today and Detail screens refresh "today" on `NSCalendarDayChanged` and whenever the app becomes active.
