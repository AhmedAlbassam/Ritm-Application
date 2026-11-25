import SwiftUI
import WidgetKit

/// Home Screen widget: today's progress with tappable check-off buttons.
struct TodayWidget: Widget {
    let kind = "RitmTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient.ritmWidget
                }
        }
        .configurationDisplayName("Today's Goals")
        .description("See today's progress and check off goals right from your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.state != .ready {
            WidgetMessageView(state: entry.state)
        } else {
            switch family {
            case .systemMedium: medium
            case .systemLarge: large
            default: small
            }
        }
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                WidgetWordmark(height: 18)
                Spacer()
                Text(entry.date, format: .dateTime.weekday(.abbreviated))
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .opacity(0.8)
            }

            Spacer(minLength: 6)

            ZStack {
                WidgetRing(progress: entry.progress, lineWidth: 9)
                VStack(spacing: 0) {
                    if entry.isAllDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .heavy))
                    } else {
                        Text("\(entry.achieved)/\(entry.total)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .minimumScaleFactor(0.6)
                    }
                }
            }
            .frame(width: 74, height: 74)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 6)

            Group {
                if entry.isAllDone {
                    Text("All done! 🎉")
                } else {
                    Text("goals done today")
                }
            }
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
    }

    // MARK: Medium

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                WidgetWordmark(height: 18)
                Spacer(minLength: 0)
                ZStack {
                    WidgetRing(progress: entry.progress, lineWidth: 8)
                    Text(entry.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.6)
                }
                .frame(width: 62, height: 62)
                Spacer(minLength: 0)
                Text("\(entry.achieved) of \(entry.total) done")
                    .font(.caption2.weight(.semibold))
                    .opacity(0.85)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.goals.prefix(3)) { goal in
                    WidgetGoalRow(goal: goal)
                }
                if entry.goals.count < 3 { Spacer(minLength: 0) }
            }
        }
        .foregroundStyle(.white)
    }

    // MARK: Large

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    WidgetWordmark(height: 22)
                    Text(entry.date, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.caption.weight(.semibold))
                        .opacity(0.85)
                }
                Spacer()
                ZStack {
                    WidgetRing(progress: entry.progress, lineWidth: 7)
                    Text("\(entry.achieved)/\(entry.total)")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.6)
                }
                .frame(width: 54, height: 54)
            }

            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)

            VStack(alignment: .leading, spacing: 11) {
                ForEach(entry.goals.prefix(5)) { goal in
                    WidgetGoalRow(goal: goal, showsProgress: true)
                }
            }

            Spacer(minLength: 0)

            HStack {
                if entry.bestStreak > 0 {
                    Label {
                        Text("Best streak: \(entry.bestStreak.daysLabel)")
                    } icon: {
                        Image(systemName: "flame.fill")
                    }
                } else {
                    Label("Check in to start a streak", systemImage: "flame")
                }
                Spacer()
                if entry.goals.count > 5 {
                    Text("+\(entry.goals.count - 5)")
                }
            }
            .font(.caption.weight(.semibold))
            .opacity(0.9)
        }
        .foregroundStyle(.white)
    }
}

#Preview(as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayEntry.sample
}

#Preview(as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayEntry.sample
}

#Preview(as: .systemLarge) {
    TodayWidget()
} timeline: {
    TodayEntry.sample
}
