import SwiftUI

/// Grid with one cell per challenge day. Tap a past day (or today) to update it.
struct HistoryGridView: View {
    let goal: Goal
    let today: Date
    let onToggle: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let days = goal.challengeDays(asOf: today)
        let completed = goal.completedDates
        let color = goal.category.color
        let calendar = Calendar.current

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Check-in History")
                    .font(.headline)
                Spacer()
                if let first = days.first, let last = days.last {
                    Text("\(first.formatted(.dateTime.month(.abbreviated).day())) – \(last.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.element) { index, day in
                    DayCell(
                        date: day,
                        dayNumber: index + 1,
                        status: status(for: day, completed: completed),
                        isToday: calendar.isDate(day, inSameDayAs: today),
                        color: color
                    ) {
                        onToggle(day)
                    }
                }
            }

            HStack(spacing: 14) {
                legendItem(color: color, label: "Achieved")
                legendItem(color: Color(.systemFill), label: "Missed")
                legendItem(color: color.opacity(0.12), label: "Today", outlined: color)
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("Forgot to check in? Tap any past day to update it.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .cardStyle(cornerRadius: 22)
    }

    private func status(for day: Date, completed: Set<Date>) -> DayCell.Status {
        let normalized = day.startOfDay
        if completed.contains(normalized) { return .completed }
        if normalized > today.startOfDay { return .upcoming }
        if Calendar.current.isDate(normalized, inSameDayAs: today) { return .pending }
        return .missed
    }

    private func legendItem(color: Color, label: String, outlined: Color? = nil) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(outlined ?? .clear, lineWidth: 1.5)
                )
                .frame(width: 12, height: 12)
            Text(label)
        }
    }
}
