import Foundation
import SwiftData

/// A permanently earned achievement badge or goal milestone.
/// Once earned it stays earned, even if a check-in is later undone.
@Model
final class AchievementRecord {
    /// "achievement.<id>" or "milestone.<goalUUID>.<percent>"
    @Attribute(.unique) var key: String
    var unlockedAt: Date
    /// For goal milestones: the goal's title and category at the time it was earned.
    var goalTitle: String?
    var categoryRawValue: String?
    /// For goal milestones: the percentage reached (25, 50, 75, 100).
    var value: Int

    init(key: String, unlockedAt: Date = .now, goalTitle: String? = nil, categoryRawValue: String? = nil, value: Int = 0) {
        self.key = key
        self.unlockedAt = unlockedAt
        self.goalTitle = goalTitle
        self.categoryRawValue = categoryRawValue
        self.value = value
    }

    var isMilestone: Bool { key.hasPrefix(AchievementRecord.milestonePrefix) }

    static let achievementPrefix = "achievement."
    static let milestonePrefix = "milestone."

    static func achievementKey(_ id: String) -> String { achievementPrefix + id }

    static func milestoneKey(goalID: UUID, percent: Int) -> String {
        "\(milestonePrefix)\(goalID.uuidString).\(percent)"
    }
}
