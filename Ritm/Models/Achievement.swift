import SwiftUI

enum AchievementTier: Int, CaseIterable, Comparable {
    case bronze, silver, gold, legendary

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .bronze: String(localized: "Bronze")
        case .silver: String(localized: "Silver")
        case .gold: String(localized: "Gold")
        case .legendary: String(localized: "Legendary")
        }
    }

    var points: Int {
        switch self {
        case .bronze: 10
        case .silver: 25
        case .gold: 50
        case .legendary: 100
        }
    }

    /// Color of the outer ring around a badge.
    var ringColors: [Color] {
        switch self {
        case .bronze: [Color(red: 0.80, green: 0.50, blue: 0.25), Color(red: 0.95, green: 0.70, blue: 0.45)]
        case .silver: [Color(red: 0.62, green: 0.66, blue: 0.72), Color(red: 0.90, green: 0.92, blue: 0.95)]
        case .gold: [Color(red: 0.95, green: 0.70, blue: 0.10), Color(red: 1.00, green: 0.88, blue: 0.40)]
        case .legendary: [.pink, .purple, .blue, .mint]
        }
    }
}

enum AchievementGroup: CaseIterable {
    case streaks, consistency, challenges, checkIns, variety

    var title: String {
        switch self {
        case .streaks: String(localized: "Streaks")
        case .consistency: String(localized: "Perfect Days")
        case .challenges: String(localized: "Challenges")
        case .checkIns: String(localized: "Check-ins")
        case .variety: String(localized: "Balance")
        }
    }
}

/// Numbers the achievements are measured against.
struct AchievementStats {
    var bestStreak = 0
    var totalCheckIns = 0
    var perfectDays = 0
    var longestPerfectRun = 0
    var completedChallenges = 0
    var categoriesUsed = 0
}

/// Every badge that can be earned in Ritm.
enum Achievement: String, CaseIterable, Identifiable {
    case firstStep
    case streak3, streak7, streak14, streak21, streak30, streak50, streak100
    case perfectDay, perfectWeek
    case firstChallenge, threeChallenges, fiveChallenges
    case checkIns10, checkIns50, checkIns100, checkIns365
    case explorer, balancedLife

    var id: String { rawValue }
    var recordKey: String { AchievementRecord.achievementKey(rawValue) }

    var group: AchievementGroup {
        switch self {
        case .streak3, .streak7, .streak14, .streak21, .streak30, .streak50, .streak100: .streaks
        case .perfectDay, .perfectWeek: .consistency
        case .firstChallenge, .threeChallenges, .fiveChallenges: .challenges
        case .firstStep, .checkIns10, .checkIns50, .checkIns100, .checkIns365: .checkIns
        case .explorer, .balancedLife: .variety
        }
    }

    var tier: AchievementTier {
        switch self {
        case .firstStep, .streak3, .checkIns10, .explorer: .bronze
        case .streak7, .streak14, .perfectDay, .firstChallenge, .checkIns50: .silver
        case .streak21, .streak30, .perfectWeek, .threeChallenges, .checkIns100, .balancedLife: .gold
        case .streak50, .streak100, .fiveChallenges, .checkIns365: .legendary
        }
    }

    var target: Int {
        switch self {
        case .firstStep, .perfectDay, .firstChallenge: 1
        case .streak3, .threeChallenges, .explorer: 3
        case .streak7, .perfectWeek: 7
        case .streak14: 14
        case .streak21: 21
        case .streak30: 30
        case .streak50, .checkIns50: 50
        case .streak100, .checkIns100: 100
        case .fiveChallenges: 5
        case .checkIns10: 10
        case .checkIns365: 365
        case .balancedLife: GoalCategory.allCases.count
        }
    }

    func currentValue(in stats: AchievementStats) -> Int {
        switch group {
        case .streaks: stats.bestStreak
        case .checkIns: stats.totalCheckIns
        case .challenges: stats.completedChallenges
        case .variety: stats.categoriesUsed
        case .consistency: self == .perfectWeek ? stats.longestPerfectRun : stats.perfectDays
        }
    }

    func isUnlocked(in stats: AchievementStats) -> Bool {
        currentValue(in: stats) >= target
    }

    var icon: String {
        switch self {
        case .firstStep: "shoeprints.fill"
        case .streak3: "flame"
        case .streak7: "flame.fill"
        case .streak14: "bolt.fill"
        case .streak21: "leaf.fill"
        case .streak30: "calendar.badge.checkmark"
        case .streak50: "star.fill"
        case .streak100: "crown.fill"
        case .perfectDay: "sun.max.fill"
        case .perfectWeek: "sparkles"
        case .firstChallenge: "trophy.fill"
        case .threeChallenges: "medal.fill"
        case .fiveChallenges: "mountain.2.fill"
        case .checkIns10: "checkmark.circle.fill"
        case .checkIns50: "checkmark.seal.fill"
        case .checkIns100: "rosette"
        case .checkIns365: "globe.americas.fill"
        case .explorer: "map.fill"
        case .balancedLife: "circle.hexagongrid.fill"
        }
    }

    /// The badge's face colors.
    var colors: [Color] {
        switch group {
        case .streaks: [.orange, .red]
        case .consistency: [.yellow, .orange]
        case .challenges: [.purple, .indigo]
        case .checkIns: [.mint, .teal]
        case .variety: [.blue, .cyan]
        }
    }

    var title: String {
        switch self {
        case .firstStep: String(localized: "First Step")
        case .streak3: String(localized: "Warming Up")
        case .streak7: String(localized: "One Week Strong")
        case .streak14: String(localized: "Two Weeks Steady")
        case .streak21: String(localized: "Habit Formed")
        case .streak30: String(localized: "Monthly Master")
        case .streak50: String(localized: "Unstoppable")
        case .streak100: String(localized: "Century Legend")
        case .perfectDay: String(localized: "Perfect Day")
        case .perfectWeek: String(localized: "Perfect Week")
        case .firstChallenge: String(localized: "Challenge Champion")
        case .threeChallenges: String(localized: "Triple Crown")
        case .fiveChallenges: String(localized: "Goal Crusher")
        case .checkIns10: String(localized: "Getting Started")
        case .checkIns50: String(localized: "Committed")
        case .checkIns100: String(localized: "Hundred Club")
        case .checkIns365: String(localized: "Year of Wins")
        case .explorer: String(localized: "Explorer")
        case .balancedLife: String(localized: "Balanced Life")
        }
    }

    var detail: String {
        switch self {
        case .firstStep: String(localized: "Complete your very first check-in.")
        case .streak3: String(localized: "Reach a 3-day streak on any goal.")
        case .streak7: String(localized: "Reach a 7-day streak on any goal.")
        case .streak14: String(localized: "Reach a 14-day streak on any goal.")
        case .streak21: String(localized: "Reach a 21-day streak. That's how habits are made!")
        case .streak30: String(localized: "Reach a 30-day streak on any goal.")
        case .streak50: String(localized: "Reach a 50-day streak on any goal.")
        case .streak100: String(localized: "Reach a 100-day streak. Truly legendary!")
        case .perfectDay: String(localized: "Achieve all of your goals in a single day (at least 2 goals).")
        case .perfectWeek: String(localized: "Have 7 perfect days in a row.")
        case .firstChallenge: String(localized: "Complete your first challenge.")
        case .threeChallenges: String(localized: "Complete 3 challenges.")
        case .fiveChallenges: String(localized: "Complete 5 challenges.")
        case .checkIns10: String(localized: "Check in 10 times.")
        case .checkIns50: String(localized: "Check in 50 times.")
        case .checkIns100: String(localized: "Check in 100 times.")
        case .checkIns365: String(localized: "Check in 365 times. A whole year of wins!")
        case .explorer: String(localized: "Create goals in 3 different life areas.")
        case .balancedLife: String(localized: "Create goals in every life area.")
        }
    }
}

/// Progress milestones celebrated for each individual goal.
enum GoalMilestone: Int, CaseIterable {
    case quarter = 25, half = 50, threeQuarters = 75, complete = 100

    var title: String {
        switch self {
        case .quarter: String(localized: "Great start!")
        case .half: String(localized: "Halfway there!")
        case .threeQuarters: String(localized: "Almost there!")
        case .complete: String(localized: "Challenge complete!")
        }
    }

    var icon: String {
        switch self {
        case .quarter: "figure.walk"
        case .half: "flag.fill"
        case .threeQuarters: "figure.run"
        case .complete: "trophy.fill"
        }
    }

    /// Number of check-ins needed to reach this milestone.
    func requiredDays(for target: Int) -> Int {
        max(1, Int((Double(target) * Double(rawValue) / 100).rounded(.up)))
    }

    /// Short challenges only celebrate halfway and completion, so they don't feel noisy.
    static func applicable(for target: Int) -> [GoalMilestone] {
        target < 8 ? [.half, .complete] : allCases
    }
}
