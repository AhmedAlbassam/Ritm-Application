import SwiftUI
import Observation

/// Presentation state and actions for the Today screen.
/// Goals themselves come from `@Query` in the view; this model filters and acts on them.
@MainActor
@Observable
final class TodayViewModel {
    var selectedCategory: GoalCategory?
    /// Normalized "today". Refreshed when the app becomes active or the day rolls over.
    private(set) var today: Date = Date.now.startOfDay
    var addGoalRequest: AddGoalRequest?
    var celebrationMessage: String?

    func refreshToday() {
        let now = Date.now.startOfDay
        if now != today { today = now }
    }

    // MARK: Derived lists

    /// Goals still in progress, plus any that were finished with today's check-in.
    func activeGoals(from goals: [Goal]) -> [Goal] {
        goals.filter { !$0.isChallengeComplete || $0.isAchieved(on: today) }
    }

    func visibleActiveGoals(from goals: [Goal]) -> [Goal] {
        filtered(activeGoals(from: goals))
    }

    func visibleCompletedChallenges(from goals: [Goal]) -> [Goal] {
        filtered(goals.filter { $0.isChallengeComplete && !$0.isAchieved(on: today) })
    }

    func summary(for goals: [Goal]) -> (achieved: Int, total: Int) {
        let active = activeGoals(from: goals)
        return (active.filter { $0.isAchieved(on: today) }.count, active.count)
    }

    func categoryCounts(for goals: [Goal]) -> [GoalCategory: Int] {
        Dictionary(grouping: goals, by: \.category).mapValues(\.count)
    }

    private func filtered(_ goals: [Goal]) -> [Goal] {
        guard let selectedCategory else { return goals }
        return goals.filter { $0.category == selectedCategory }
    }

    // MARK: Actions

    func toggle(_ goal: Goal) {
        refreshToday()
        let wasComplete = goal.isChallengeComplete

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            goal.toggleAchieved(on: today)
        }

        let isComplete = goal.isChallengeComplete
        guard wasComplete != isComplete else { return }

        // Stop reminders once a challenge is finished; resume if it's undone.
        Task { await NotificationManager.shared.scheduleReminder(for: goal, requestPermissionIfNeeded: false) }

        if isComplete {
            withAnimation(.spring) {
                celebrationMessage = "Challenge complete: \(goal.title) 🎉"
            }
        }
    }
}
