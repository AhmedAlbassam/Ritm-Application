import Foundation

/// An immutable, value-type copy of a goal's data. Used for widgets, insights
/// and achievements so heavy calculations don't repeatedly walk SwiftData relationships.
struct GoalSnapshot: Identifiable, Hashable {
    let id: UUID
    let title: String
    let category: GoalCategory
    let targetDays: Int
    let startDate: Date
    let createdAt: Date
    let isArchived: Bool
    let reminderEnabled: Bool
    let reminderTime: Date
    let completedDates: Set<Date>

    init(_ goal: Goal) {
        id = goal.id
        title = goal.title
        category = goal.category
        targetDays = goal.targetDays
        startDate = goal.startDate.startOfDay
        createdAt = goal.createdAt
        isArchived = goal.isArchived
        reminderEnabled = goal.reminderEnabled
        reminderTime = goal.reminderTime
        completedDates = goal.completedDates
    }

    var completedCount: Int { completedDates.count }
    var isComplete: Bool { completedCount >= targetDays }
    var progress: Double { targetDays > 0 ? min(1, Double(completedCount) / Double(targetDays)) : 0 }
    var completionDate: Date? { StreakMath.completionDate(in: completedDates, target: targetDays) }
    var longestStreak: Int { StreakMath.longest(in: completedDates) }

    func streak(asOf date: Date) -> Int { StreakMath.current(in: completedDates, asOf: date) }

    func isAchieved(on day: Date) -> Bool { completedDates.contains(day.startOfDay) }

    /// Whether the goal "counted" on that day: started, and not yet finished before it.
    func isActive(on day: Date) -> Bool {
        let day = day.startOfDay
        guard day >= startDate else { return false }
        if let completionDate { return day <= completionDate }
        return true
    }
}
