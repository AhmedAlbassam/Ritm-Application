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
    /// "1 day" / "12 days"
    var daysLabel: String {
        self == 1 ? "1 day" : "\(self) days"
    }
}
