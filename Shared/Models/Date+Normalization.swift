import Foundation

extension Date {
    /// The date normalized to midnight in the user's current calendar.
    /// Every daily log is stored this way so the time of day never matters.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Adds whole days to the normalized start of this date.
    func addingDays(_ days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: self)) ?? self
    }
}

extension Calendar {
    /// Number of calendar days between two dates, ignoring the time of day.
    func numberOfDays(from start: Date, to end: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: start), to: startOfDay(for: end)).day ?? 0
    }
}

extension Int {
    /// Localized, pluralized "1 day" / "12 days" / "يومان" …
    var daysLabel: String {
        String(localized: "\(self) days")
    }
}

/// Streak math shared by `Goal`, `GoalSnapshot`, insights and achievements.
enum StreakMath {
    /// Consecutive completed days ending today. If today isn't done yet,
    /// the streak counted through yesterday is still "alive".
    static func current(in completed: Set<Date>, asOf date: Date) -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: date)
        if !completed.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while completed.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// Longest run of consecutive days in the set.
    static func longest(in completed: Set<Date>) -> Int {
        let calendar = Calendar.current
        var best = 0
        var run = 0
        var previous: Date?
        for day in completed.sorted() {
            if let previous,
               let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }

    /// The day the `target`-th check-in happened, if reached.
    static func completionDate(in completed: Set<Date>, target: Int) -> Date? {
        guard target > 0, completed.count >= target else { return nil }
        return completed.sorted()[target - 1]
    }
}
