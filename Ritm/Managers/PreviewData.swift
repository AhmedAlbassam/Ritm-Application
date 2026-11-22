#if DEBUG
import Foundation
import SwiftData

/// In-memory sample data for SwiftUI previews.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: Goal.self, DailyLog.self, configurations: configuration)
            populate(container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    static var sampleGoal: Goal {
        let goals = (try? container.mainContext.fetch(FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        return goals.first!
    }

    private static func populate(_ context: ModelContext) {
        let today = Date.now.startOfDay

        let samples: [(String, GoalCategory, Int, Int, [Int], Bool)] = [
            // title, category, target, started N days ago, missed day offsets, reminder
            ("Walk for 30 min daily", .health, 30, 13, [4, 9], true),
            ("Read 10 pages", .learning, 21, 6, [2], false),
            ("Deep work for 1 hour", .work, 14, 3, [], true),
            ("Track every expense", .finance, 7, 7, [], false),
        ]

        for (title, category, target, daysAgo, missed, reminder) in samples {
            let goal = Goal(
                title: title,
                category: category,
                targetDays: target,
                startDate: today.addingDays(-daysAgo),
                reminderEnabled: reminder
            )
            context.insert(goal)
            // Leave "today" unchecked so the check-in button can be tried.
            for offset in 0..<daysAgo where !missed.contains(offset) {
                goal.setAchieved(true, on: goal.startDate.addingDays(offset))
            }
        }
        try? context.save()
    }
}
#endif
