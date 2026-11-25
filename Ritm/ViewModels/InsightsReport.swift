import SwiftUI

enum InsightsRange: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: String(localized: "Week")
        case .month: String(localized: "Month")
        case .year: String(localized: "Year")
        }
    }

    /// Number of days covered (the year range is grouped by month in the chart).
    var dayCount: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .year: 365
        }
    }
}

struct ChartPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let checkIns: Int
}

struct CategoryCount: Identifiable {
    var id: GoalCategory { category }
    let category: GoalCategory
    let count: Int
}

struct WeekdayRate: Identifiable {
    var id: Int { weekday }
    /// 1 = Sunday … 7 = Saturday (Calendar convention)
    let weekday: Int
    let symbol: String
    let rate: Double
}

struct HeatmapCell: Identifiable {
    var id: Date { date }
    let date: Date
    /// nil = nothing to track that day (or in the future)
    let intensity: Double?
}

struct GoalPerformance: Identifiable {
    var id: UUID { goal.id }
    let goal: GoalSnapshot
    let rate: Double
}

struct InsightMessage: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let text: String
}

/// Everything the Insights screen shows, computed once per render from goal snapshots.
struct InsightsReport {
    let range: InsightsRange
    let analytics: ProgressAnalytics

    let periodStart: Date
    let periodEnd: Date
    let checkIns: Int
    let previousCheckIns: Int
    let completionRate: Double?
    let perfectDays: Int
    let bestCurrentStreak: Int
    let points: [ChartPoint]
    let categories: [CategoryCount]
    let weekdays: [WeekdayRate]
    let heatmapWeeks: [[HeatmapCell]]
    let goalPerformance: [GoalPerformance]

    init(goals: [GoalSnapshot], range: InsightsRange, today: Date = .now) {
        let calendar = Calendar.current
        let analytics = ProgressAnalytics(goals: goals, today: today)
        let today = analytics.today
        self.range = range
        self.analytics = analytics

        periodEnd = today
        periodStart = today.addingDays(-(range.dayCount - 1))
        let previousEnd = periodStart.addingDays(-1)
        let previousStart = previousEnd.addingDays(-(range.dayCount - 1))

        let periodDays = analytics.days(from: periodStart, to: periodEnd)
        checkIns = periodDays.reduce(0) { $0 + analytics.checkIns(on: $1) }
        previousCheckIns = analytics.checkIns(from: previousStart, to: previousEnd)
        completionRate = analytics.completionRate(from: periodStart, to: periodEnd)
        perfectDays = periodDays.filter(analytics.isPerfectDay).count
        bestCurrentStreak = analytics.bestCurrentStreak

        // Chart: daily bars for week/month, monthly bars for the year.
        if range == .year {
            let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            points = (0..<12).reversed().compactMap { offset -> ChartPoint? in
                guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: thisMonth),
                      let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)
                else { return nil }
                let monthEnd = min(nextMonth.addingDays(-1), today)
                return ChartPoint(date: monthStart, checkIns: analytics.checkIns(from: monthStart, to: monthEnd))
            }
        } else {
            points = periodDays.map { ChartPoint(date: $0, checkIns: analytics.checkIns(on: $0)) }
        }

        // Category breakdown for the period.
        var byCategory: [GoalCategory: Int] = [:]
        for goal in goals {
            let count = goal.completedDates.filter { $0 >= periodStart && $0 <= periodEnd }.count
            if count > 0 { byCategory[goal.category, default: 0] += count }
        }
        categories = byCategory
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        // Weekday consistency over the last 12 weeks.
        let weekdayWindow = analytics.days(from: today.addingDays(-83), to: today)
        var done = [Int: Int]()
        var possible = [Int: Int]()
        for day in weekdayWindow {
            guard let completion = analytics.completion(on: day) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            done[weekday, default: 0] += completion.done
            possible[weekday, default: 0] += completion.possible
        }
        let symbols = calendar.veryShortWeekdaySymbols
        let orderedWeekdays = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        weekdays = orderedWeekdays.map { weekday in
            let total = possible[weekday] ?? 0
            return WeekdayRate(
                weekday: weekday,
                symbol: symbols[weekday - 1],
                rate: total > 0 ? Double(done[weekday] ?? 0) / Double(total) : 0
            )
        }

        // Heatmap: the last 17 weeks, columns are weeks, rows are weekdays.
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let firstWeek = weekStart.addingDays(-16 * 7)
        heatmapWeeks = (0..<17).map { week in
            (0..<7).map { dayIndex in
                let date = firstWeek.addingDays(week * 7 + dayIndex)
                guard date <= today, let completion = analytics.completion(on: date) else {
                    return HeatmapCell(date: date, intensity: nil)
                }
                return HeatmapCell(date: date, intensity: Double(completion.done) / Double(completion.possible))
            }
        }

        goalPerformance = analytics.trackedGoals
            .map { goal in
                let elapsed = max(1, min(calendar.numberOfDays(from: goal.startDate, to: today) + 1, max(goal.targetDays, goal.completedCount)))
                return GoalPerformance(goal: goal, rate: min(1, Double(goal.completedCount) / Double(elapsed)))
            }
            .sorted { $0.rate > $1.rate }
    }

    var checkInDelta: Int { checkIns - previousCheckIns }

    var bestWeekday: WeekdayRate? {
        guard let best = weekdays.max(by: { $0.rate < $1.rate }), best.rate > 0 else { return nil }
        return best
    }

    var messages: [InsightMessage] {
        var result: [InsightMessage] = []

        if checkInDelta > 0 {
            result.append(InsightMessage(icon: "arrow.up.right.circle.fill", color: .green,
                                         text: String(localized: "\(checkInDelta) more check-ins than the previous period. Keep it up!")))
        } else if checkInDelta < 0, previousCheckIns > 0 {
            result.append(InsightMessage(icon: "arrow.down.right.circle.fill", color: .orange,
                                         text: String(localized: "\(-checkInDelta) fewer check-ins than the previous period. You've got this!")))
        }

        if let bestWeekday {
            let name = Calendar.current.weekdaySymbols[bestWeekday.weekday - 1]
            result.append(InsightMessage(icon: "calendar", color: .blue,
                                         text: String(localized: "You're most consistent on \(name).")))
        }

        if bestCurrentStreak >= 2 {
            result.append(InsightMessage(icon: "flame.fill", color: .orange,
                                         text: String(localized: "Your best active streak is \(bestCurrentStreak.daysLabel). Don't break the chain!")))
        }

        if perfectDays > 0 {
            result.append(InsightMessage(icon: "sun.max.fill", color: .yellow,
                                         text: String(localized: "\(perfectDays) perfect days in this period ✨")))
        }

        if let top = goalPerformance.first, top.rate >= 0.8 {
            result.append(InsightMessage(icon: "star.fill", color: .purple,
                                         text: String(localized: "“\(top.goal.title)” is your strongest habit right now.")))
        }

        return result
    }
}
