import SwiftData
import WidgetKit

struct WidgetGoal: Identifiable {
    let id: UUID
    let title: String
    let category: GoalCategory
    let isDone: Bool
    let streak: Int
    let completed: Int
    let target: Int

    var progress: Double { target > 0 ? min(1, Double(completed) / Double(target)) : 0 }
}

struct TodayEntry: TimelineEntry {
    enum State {
        case ready
        case noGoals
        /// The App Group isn't available, so the widget can't read the app's data.
        case needsSetup
    }

    let date: Date
    let state: State
    let goals: [WidgetGoal]

    var achieved: Int { goals.filter(\.isDone).count }
    var total: Int { goals.count }
    var progress: Double { total > 0 ? Double(achieved) / Double(total) : 0 }
    var bestStreak: Int { goals.map(\.streak).max() ?? 0 }
    var isAllDone: Bool { total > 0 && achieved == total }

    static let sample = TodayEntry(
        date: .now,
        state: .ready,
        goals: [
            WidgetGoal(id: UUID(), title: String(localized: "Walk for 30 min daily"), category: .health, isDone: true, streak: 12, completed: 18, target: 30),
            WidgetGoal(id: UUID(), title: String(localized: "Read 10 pages"), category: .learning, isDone: false, streak: 5, completed: 9, target: 21),
            WidgetGoal(id: UUID(), title: String(localized: "Deep work for 1 hour"), category: .work, isDone: true, streak: 3, completed: 4, target: 14),
            WidgetGoal(id: UUID(), title: String(localized: "No takeout spending"), category: .finance, isDone: false, streak: 0, completed: 6, target: 30),
        ]
    )
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
        } else {
            completion(Self.loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = Self.loadEntry()
        // Refresh just after midnight so "today" resets. The app also reloads
        // the widgets whenever data changes.
        let nextMidnight = Date.now.addingDays(1).addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    static func loadEntry() -> TodayEntry {
        guard SharedStore.isUsingAppGroup, let container = SharedStore.sharedContainer else {
            return TodayEntry(date: .now, state: .needsSetup, goals: [])
        }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate<Goal> { $0.isArchived == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let goals = ((try? context.fetch(descriptor)) ?? []).map(GoalSnapshot.init)
        let today = Date.now.startOfDay

        let widgetGoals = goals
            // Same rule as the Today screen: hide finished challenges unless finished today.
            .filter { !$0.isComplete || $0.isAchieved(on: today) }
            .map { goal in
                WidgetGoal(
                    id: goal.id,
                    title: goal.title,
                    category: goal.category,
                    isDone: goal.isAchieved(on: today),
                    streak: goal.streak(asOf: today),
                    completed: min(goal.completedCount, goal.targetDays),
                    target: goal.targetDays
                )
            }
            // Unfinished goals first, so the next thing to do is always visible.
            .sorted { !$0.isDone && $1.isDone }

        return TodayEntry(date: .now, state: widgetGoals.isEmpty ? .noGoals : .ready, goals: widgetGoals)
    }
}
