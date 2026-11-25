import SwiftUI

/// One day in the goal history grid.
struct DayCell: View {
    enum Status {
        case completed, missed, pending, upcoming
    }

    let date: Date
    let dayNumber: Int
    let status: Status
    let isToday: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(date, format: .dateTime.day())
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(isToday ? color : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.85))
        .disabled(status == .upcoming)
        .sensoryFeedback(.selection, trigger: status)
        .accessibilityLabel("Day \(dayNumber), \(date.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityValue(Text(accessibilityStatus))
    }

    private var background: AnyShapeStyle {
        switch status {
        case .completed: AnyShapeStyle(color.gradient)
        case .missed: AnyShapeStyle(Color(.systemFill))
        case .pending: AnyShapeStyle(color.opacity(0.12))
        case .upcoming: AnyShapeStyle(Color(.tertiarySystemFill).opacity(0.5))
        }
    }

    private var foreground: Color {
        switch status {
        case .completed: .white
        case .missed: .secondary
        case .pending: color
        case .upcoming: Color.secondary.opacity(0.5)
        }
    }

    private var accessibilityStatus: String {
        switch status {
        case .completed: String(localized: "Achieved")
        case .missed: String(localized: "Missed")
        case .pending: String(localized: "Not yet checked in")
        case .upcoming: String(localized: "Upcoming")
        }
    }
}
