import Foundation

/// Pure calculations over goal snapshots, shared by Insights and Achievements.
struct ProgressAnalytics {
    let goals: [GoalSnapshot]
    let today: Date

    init(goals: [GoalSnapshot], today: Date = .now) {
        self.goals = goals
        self.today = today.startOfDay
    }

    /// Goals that count toward completion rates and perfect days.
    var trackedGoals: [GoalSnapshot] { goals.filter { !$0.isArchived } }

    var earliestStart: Date? { goals.map(\.startDate).min() }

    func activeGoals(on day: Date) -> [GoalSnapshot] {
        trackedGoals.filter { $0.isActive(on: day) }
    }

    /// Check-ins on a day, across every goal (archived included).
    func checkIns(on day: Date) -> Int {
        let day = day.startOfDay
        return goals.reduce(0) { $0 + ($1.completedDates.contains(day) ? 1 : 0) }
    }

    /// Achieved / possible on a day, for tracked goals. `nil` when nothing was active.
    func completion(on day: Date) -> (done: Int, possible: Int)? {
        let active = activeGoals(on: day)
        guard !active.isEmpty else { return nil }
        return (active.filter { $0.isAchieved(on: day) }.count, active.count)
    }

    /// A day on which every active goal (at least two) was achieved.
    func isPerfectDay(_ day: Date) -> Bool {
        guard let completion = completion(on: day) else { return false }
        return completion.possible >= 2 && completion.done == completion.possible
    }

    func days(from start: Date, to end: Date) -> [Date] {
        let count = Calendar.current.numberOfDays(from: start, to: end)
        guard count >= 0 else { return [] }
        return (0...count).map { start.addingDays($0) }
    }

    var allDays: [Date] {
        guard let earliestStart else { return [] }
        return days(from: earliestStart, to: today)
    }

    var perfectDays: [Date] { allDays.filter(isPerfectDay) }

    var longestPerfectRun: Int { StreakMath.longest(in: Set(perfectDays)) }

    var totalCheckIns: Int { goals.reduce(0) { $0 + $1.completedCount } }

    var bestStreak: Int { goals.map(\.longestStreak).max() ?? 0 }

    var bestCurrentStreak: Int { trackedGoals.map { $0.streak(asOf: today) }.max() ?? 0 }

    var completedChallenges: Int { goals.filter(\.isComplete).count }

    var categoriesUsed: Set<GoalCategory> { Set(goals.map(\.category)) }

    var achievementStats: AchievementStats {
        let perfect = perfectDays
        return AchievementStats(
            bestStreak: bestStreak,
            totalCheckIns: totalCheckIns,
            perfectDays: perfect.count,
            longestPerfectRun: StreakMath.longest(in: Set(perfect)),
            completedChallenges: completedChallenges,
            categoriesUsed: categoriesUsed.count
        )
    }

    /// Done / possible over a date range for tracked goals.
    func completionRate(from start: Date, to end: Date) -> Double? {
        var done = 0
        var possible = 0
        for day in days(from: start, to: end) {
            if let completion = completion(on: day) {
                done += completion.done
                possible += completion.possible
            }
        }
        return possible > 0 ? Double(done) / Double(possible) : nil
    }

    func checkIns(from start: Date, to end: Date) -> Int {
        days(from: start, to: end).reduce(0) { $0 + checkIns(on: $1) }
    }
}
