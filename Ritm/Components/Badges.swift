import SwiftUI

struct CategoryBadge: View {
    let category: GoalCategory

    var body: some View {
        Label(category.title, systemImage: category.icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(category.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(category.color.opacity(0.14), in: Capsule())
    }
}

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .symbolEffect(.bounce, value: streak)
            Text("\(streak)")
                .contentTransition(.numericText())
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(streak > 0 ? Color.orange : Color.secondary.opacity(0.6))
        .animation(.spring, value: streak)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak: \(streak.daysLabel)")
    }
}

struct ReminderPill: View {
    let time: Date

    var body: some View {
        Label {
            Text(time, format: .dateTime.hour().minute())
        } icon: {
            Image(systemName: "bell.fill")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .accessibilityLabel("Reminder at \(time.formatted(date: .omitted, time: .shortened))")
    }
}

struct CompletedBadge: View {
    var body: some View {
        Label("Done", systemImage: "trophy.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.14), in: Capsule())
    }
}
