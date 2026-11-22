import Foundation

/// A starter idea offered in the empty state to pre-fill the Add Goal sheet.
struct GoalTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: GoalCategory
    let targetDays: Int

    static let suggestions: [GoalTemplate] = [
        GoalTemplate(title: "Walk for 30 min daily", category: .health, targetDays: 30),
        GoalTemplate(title: "Read 10 pages", category: .learning, targetDays: 21),
        GoalTemplate(title: "Deep work for 1 hour", category: .work, targetDays: 14),
        GoalTemplate(title: "No takeout spending", category: .finance, targetDays: 30),
    ]
}

/// Drives `.sheet(item:)` for creating a new goal, optionally from a template.
struct AddGoalRequest: Identifiable {
    let id = UUID()
    var template: GoalTemplate?
}
