import AppIntents
import SwiftUI
import WidgetKit

extension LinearGradient {
    static let ritmWidget = LinearGradient(
        colors: [Color(red: 0.31, green: 0.36, blue: 0.95), Color(red: 0.48, green: 0.29, blue: 0.92), Color(red: 0.72, green: 0.24, blue: 0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct WidgetRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
        }
    }
}

struct WidgetWordmark: View {
    var height: CGFloat = 16

    var body: some View {
        Image("Wordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .foregroundStyle(.white)
    }
}

/// One goal with an interactive check-off button.
struct WidgetGoalRow: View {
    let goal: WidgetGoal
    var showsProgress = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: goal.category.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(goal.category.color)
                .frame(width: 26, height: 26)
                .background(.white, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .strikethrough(goal.isDone, color: .white.opacity(0.6))
                    .opacity(goal.isDone ? 0.75 : 1)

                if showsProgress {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.22))
                            Capsule().fill(.white)
                                .frame(width: max(4, proxy.size.width * goal.progress))
                        }
                    }
                    .frame(height: 4)
                }

                HStack(spacing: 6) {
                    Text("\(goal.completed) / \(goal.target) days")
                    if goal.streak > 0 {
                        Label {
                            Text(goal.streak, format: .number)
                        } icon: {
                            Image(systemName: "flame.fill")
                        }
                        .labelStyle(CompactLabelStyle())
                    }
                }
                .font(.caption2.weight(.medium))
                .opacity(0.8)
            }

            Spacer(minLength: 4)

            Button(intent: ToggleGoalIntent(goalID: goal.id)) {
                Image(systemName: goal.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(goal.isDone ? Text("Achieved today") : Text("Mark as achieved today"))
        }
        .foregroundStyle(.white)
    }
}

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
            configuration.title
        }
    }
}

/// Shown when the widget can't show goals yet.
struct WidgetMessageView: View {
    let state: TodayEntry.State

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetWordmark(height: 22)
            Spacer(minLength: 0)
            Image(systemName: state == .needsSetup ? "gearshape.fill" : "plus.circle.fill")
                .font(.title2)
            if state == .needsSetup {
                Text("Open Ritm to finish setting up widgets.")
                    .font(.caption.weight(.semibold))
            } else {
                Text("Add your first goal in Ritm.")
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
