import SwiftUI

/// A goal row on the Today screen. The left part opens the detail screen;
/// the check-in button on the right toggles today's achievement.
struct GoalCardView: View {
    let goal: Goal
    let today: Date
    let onToggle: () -> Void

    var body: some View {
        let category = goal.category
        let achieved = goal.isAchieved(on: today)

        HStack(spacing: 14) {
            NavigationLink(value: goal) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        CategoryBadge(category: category)
                        if goal.isChallengeComplete {
                            CompletedBadge()
                        }
                        Spacer(minLength: 0)
                        StreakBadge(streak: goal.streak(asOf: today))
                    }

                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    VStack(alignment: .leading, spacing: 6) {
                        LinearProgressBar(progress: goal.progressRatio, color: category.color)
                        HStack(spacing: 8) {
                            Text("\(goal.displayedCompletedDays) / \(goal.targetDays) days")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                            Spacer(minLength: 0)
                            if goal.reminderEnabled {
                                ReminderPill(time: goal.reminderTime)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            CheckInButton(isCompleted: achieved, color: category.color, action: onToggle)
        }
        .padding(16)
        .cardStyle(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(achieved ? category.color.opacity(0.4) : .clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: achieved)
    }
}
