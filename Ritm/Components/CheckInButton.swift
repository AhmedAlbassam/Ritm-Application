import SwiftUI

/// Large circular "Achieved Today" toggle on each goal card.
struct CheckInButton: View {
    let isCompleted: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.1)))
                Circle()
                    .strokeBorder(color.opacity(isCompleted ? 0 : 0.35), style: StrokeStyle(lineWidth: 2, dash: isCompleted ? [] : [4, 4]))
                Image(systemName: "checkmark")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(isCompleted ? Color.white : color.opacity(0.45))
                    .scaleEffect(isCompleted ? 1.1 : 0.9)
                    .symbolEffect(.bounce, value: isCompleted)
            }
            .frame(width: 56, height: 56)
            .shadow(color: isCompleted ? color.opacity(0.4) : .clear, radius: 8, y: 4)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isCompleted)
            .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.86))
        .sensoryFeedback(trigger: isCompleted) { _, newValue in
            newValue ? .success : .impact(weight: .light)
        }
        .accessibilityLabel(isCompleted ? "Achieved today" : "Mark as achieved today")
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }
}
