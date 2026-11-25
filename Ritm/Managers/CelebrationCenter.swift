import Observation
import SwiftData
import SwiftUI
import WidgetKit

/// Something worth celebrating with the full-screen animation.
struct Celebration: Identifiable, Equatable {
    enum Kind: Equatable {
        case achievement(Achievement)
        case milestone(GoalMilestone)
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let message: String
    let icon: String
    let colors: [Color]
    let ringColors: [Color]
    let date: Date

    var headline: String {
        switch kind {
        case .achievement: String(localized: "Achievement Unlocked!")
        case .milestone: String(localized: "Milestone Reached!")
        }
    }

    var shareText: String {
        switch kind {
        case .achievement: String(localized: "I just unlocked “\(title)” on Ritm! 🎉")
        case .milestone: "\(title) \(message) #Ritm"
        }
    }

    static func achievement(_ achievement: Achievement, date: Date = .now) -> Celebration {
        Celebration(
            kind: .achievement(achievement),
            title: achievement.title,
            message: achievement.detail,
            icon: achievement.icon,
            colors: achievement.colors,
            ringColors: achievement.tier.ringColors,
            date: date
        )
    }

    static func milestone(_ milestone: GoalMilestone, goalTitle: String, category: GoalCategory, done: Int, target: Int, date: Date = .now) -> Celebration {
        Celebration(
            kind: .milestone(milestone),
            title: milestone.title,
            message: String(localized: "You've completed \(done) of \(target) days of “\(goalTitle)”."),
            icon: milestone.icon,
            colors: [category.color, category.color.opacity(0.7)],
            ringColors: milestone == .complete ? AchievementTier.gold.ringColors : [.white.opacity(0.9), .white.opacity(0.6)],
            date: date
        )
    }
}

/// Detects newly earned achievements / milestones and queues celebrations for them.
@MainActor
@Observable
final class CelebrationCenter {
    static let shared = CelebrationCenter()

    private(set) var queue: [Celebration] = []
    var current: Celebration? { queue.first }

    private static let bootstrappedKey = "achievementsBootstrapped"

    private init() {}

    func dismissCurrent() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
    }

    /// Compares what the data says has been earned with what's already recorded,
    /// records anything new and queues a celebration for it.
    func evaluate(in context: ModelContext) {
        guard let goals = try? context.fetch(FetchDescriptor<Goal>()),
              let records = try? context.fetch(FetchDescriptor<AchievementRecord>())
        else { return }

        let existingKeys = Set(records.map(\.key))
        let snapshots = goals.map(GoalSnapshot.init)
        var newCelebrations: [Celebration] = []

        // Per-goal milestones
        for goal in snapshots {
            for milestone in GoalMilestone.applicable(for: goal.targetDays)
            where goal.completedCount >= milestone.requiredDays(for: goal.targetDays) {
                let key = AchievementRecord.milestoneKey(goalID: goal.id, percent: milestone.rawValue)
                guard !existingKeys.contains(key) else { continue }
                context.insert(AchievementRecord(
                    key: key,
                    goalTitle: goal.title,
                    categoryRawValue: goal.category.rawValue,
                    value: milestone.rawValue
                ))
                newCelebrations.append(.milestone(
                    milestone,
                    goalTitle: goal.title,
                    category: goal.category,
                    done: min(goal.completedCount, goal.targetDays),
                    target: goal.targetDays
                ))
            }
        }

        // Badges
        let stats = ProgressAnalytics(goals: snapshots).achievementStats
        for achievement in Achievement.allCases
        where achievement.isUnlocked(in: stats) && !existingKeys.contains(achievement.recordKey) {
            context.insert(AchievementRecord(key: achievement.recordKey))
            newCelebrations.append(.achievement(achievement))
        }

        let isFirstRun = !SharedStore.defaults.bool(forKey: Self.bootstrappedKey)
        SharedStore.defaults.set(true, forKey: Self.bootstrappedKey)

        guard !newCelebrations.isEmpty else { return }
        try? context.save()

        // On the very first run (e.g. after an update), record silently instead of
        // flooding the user with celebrations for past progress.
        guard !isFirstRun else { return }

        // If many arrive at once, show only the most meaningful few.
        let ordered = Array(newCelebrations.sorted { rank($0) > rank($1) }.prefix(4))
        // Let the check-in animation land before the celebration takes over the screen.
        Task {
            try? await Task.sleep(for: .milliseconds(550))
            queue.append(contentsOf: ordered)
        }
    }

    private func rank(_ celebration: Celebration) -> Int {
        switch celebration.kind {
        case .achievement(let achievement): 100 + achievement.tier.rawValue * 10
        case .milestone(let milestone): milestone.rawValue / 25
        }
    }
}

/// One place to call after anything changes goal data.
@MainActor
enum AppEvents {
    static func goalsDidChange(in context: ModelContext) {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        CelebrationCenter.shared.evaluate(in: context)
    }
}
