import Foundation
import Observation

/// Editable draft backing the Add / Edit Goal sheet.
@Observable
final class GoalFormModel {
    static let durationPresets = [7, 14, 21, 30, 60, 90]
    static let dayRange = 1...365
    static var titlePlaceholder: String { String(localized: "Walk for 30 min daily") }

    var title: String
    var category: GoalCategory
    var targetDays: Int
    var reminderEnabled: Bool
    var reminderTime: Date
    let isEditing: Bool

    init(goal: Goal? = nil, template: GoalTemplate? = nil) {
        if let goal {
            title = goal.title
            category = goal.category
            targetDays = goal.targetDays
            reminderEnabled = goal.reminderEnabled
            reminderTime = goal.reminderTime
            isEditing = true
        } else {
            title = template?.title ?? ""
            category = template?.category ?? .health
            targetDays = template?.targetDays ?? 30
            reminderEnabled = false
            reminderTime = Goal.defaultReminderTime
            isEditing = false
        }
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedTitle.isEmpty && Self.dayRange.contains(targetDays)
    }

    var isCustomDuration: Bool {
        !Self.durationPresets.contains(targetDays)
    }

    var notificationPreviewMessage: String {
        Goal.reminderMessage(for: trimmedTitle.isEmpty ? Self.titlePlaceholder : trimmedTitle)
    }

    func earliestFinishDate(from start: Date = .now) -> Date {
        start.addingDays(targetDays - 1)
    }

    func apply(to goal: Goal) {
        goal.title = trimmedTitle
        goal.category = category
        goal.targetDays = targetDays
        goal.reminderEnabled = reminderEnabled
        goal.reminderTime = reminderTime
    }

    func makeGoal() -> Goal {
        Goal(
            title: trimmedTitle,
            category: category,
            targetDays: targetDays,
            startDate: .now,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )
    }
}
