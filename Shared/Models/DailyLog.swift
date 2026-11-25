import Foundation
import SwiftData

/// One check-in record for a goal on a specific calendar day.
@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID
    /// Always normalized to `Calendar.current.startOfDay(for:)`.
    var date: Date
    var isCompleted: Bool
    var goal: Goal?

    init(date: Date = .now, isCompleted: Bool = true) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
    }
}
