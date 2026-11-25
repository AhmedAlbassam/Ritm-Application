import Foundation
import SwiftData

/// A personal goal that the user checks in on every day for `targetDays` days.
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Backing storage for `category`. A plain String keeps the value usable in
    /// `#Predicate` queries and makes the store resilient to future enum changes.
    var categoryRawValue: String
    var targetDays: Int
    /// Normalized to the start of the day the challenge began.
    var startDate: Date
    var reminderEnabled: Bool
    var reminderTime: Date
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DailyLog.goal)
    var logs: [DailyLog] = []

    init(
        title: String,
        category: GoalCategory,
        targetDays: Int,
        startDate: Date = .now,
        reminderEnabled: Bool = false,
        reminderTime: Date = Goal.defaultReminderTime,
        isArchived: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.categoryRawValue = category.rawValue
        self.targetDays = max(1, targetDays)
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.isArchived = isArchived
        self.createdAt = .now
    }

    /// 9:00 AM today.
    static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    }
}

// MARK: - Derived state

extension Goal {
    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRawValue) ?? .personal }
        set { categoryRawValue = newValue.rawValue }
    }

    /// The unique set of normalized days on which the goal was achieved.
    var completedDates: Set<Date> {
        let calendar = Calendar.current
        return Set(logs.lazy.filter(\.isCompleted).map { calendar.startOfDay(for: $0.date) })
    }

    var completedDaysCount: Int { completedDates.count }

    /// Completed days capped at the target, for display ("12 / 30 days").
    var displayedCompletedDays: Int { min(completedDaysCount, targetDays) }

    /// 0.0 ... 1.0
    var progressRatio: Double {
        guard targetDays > 0 else { return 0 }
        return min(1, Double(completedDaysCount) / Double(targetDays))
    }

    var isAchievedToday: Bool { isAchieved(on: .now) }

    var currentStreak: Int { streak(asOf: .now) }

    var isChallengeComplete: Bool { completedDaysCount >= targetDays }

    /// Check-ins still needed to finish the challenge.
    var remainingDays: Int { max(0, targetDays - completedDaysCount) }

    /// The last day of the challenge if every single day is achieved.
    var plannedEndDate: Date { startDate.addingDays(targetDays - 1) }

    var longestStreak: Int { StreakMath.longest(in: completedDates) }

    var reminderMessage: String { Goal.reminderMessage(for: title) }

    static func reminderMessage(for title: String) -> String {
        let cleaned = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".!"))
        return String(localized: "Time for your daily goal: \(cleaned)!")
    }
}

// MARK: - Date-based queries

extension Goal {
    func log(for date: Date) -> DailyLog? {
        let calendar = Calendar.current
        return logs.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func isAchieved(on date: Date) -> Bool {
        log(for: date)?.isCompleted ?? false
    }

    func streak(asOf date: Date) -> Int {
        StreakMath.current(in: completedDates, asOf: date)
    }

    /// Days since the challenge started, counting the start day (0 before it starts).
    func daysElapsed(asOf date: Date) -> Int {
        max(0, Calendar.current.numberOfDays(from: startDate, to: date) + 1)
    }

    /// Share of elapsed days that were achieved.
    func successRate(asOf date: Date) -> Double {
        let elapsed = max(1, min(daysElapsed(asOf: date), max(targetDays, completedDaysCount)))
        return min(1, Double(completedDaysCount) / Double(elapsed))
    }

    /// Every day shown in the history grid: the full planned challenge, extended
    /// up to today if the user is running past the planned end date.
    func challengeDays(asOf date: Date) -> [Date] {
        let count = max(targetDays, daysElapsed(asOf: date))
        return (0..<count).map { startDate.addingDays($0) }
    }

    /// Only days from the start date through today can be logged.
    func canLog(on date: Date, today: Date = .now) -> Bool {
        let day = date.startOfDay
        return day >= startDate.startOfDay && day <= today.startOfDay
    }
}

// MARK: - Mutations

extension Goal {
    func setAchieved(_ achieved: Bool, on date: Date) {
        if let existing = log(for: date) {
            existing.isCompleted = achieved
        } else if achieved {
            let newLog = DailyLog(date: date, isCompleted: true)
            modelContext?.insert(newLog)
            logs.append(newLog)
        }
    }

    /// Flips the check-in for the given day and returns the new state.
    @discardableResult
    func toggleAchieved(on date: Date = .now) -> Bool {
        let newValue = !isAchieved(on: date)
        setAchieved(newValue, on: date)
        return newValue
    }
}
