import SwiftUI
import WidgetKit

/// Lock Screen widgets: a progress gauge, a summary line, and an inline status.
struct LockScreenWidget: Widget {
    let kind = "RitmLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    AccessoryWidgetBackground()
                }
        }
        .configurationDisplayName("Ritm Progress")
        .description("Keep today's goals in view on your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: inline
        }
    }

    private var circular: some View {
        Gauge(value: Double(entry.achieved), in: 0...Double(max(entry.total, 1))) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            if entry.isAllDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .heavy))
            } else {
                Text("\(entry.achieved)/\(entry.total)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                Text("Ritm")
                    .fontWeight(.bold)
                if entry.bestStreak > 0 {
                    Spacer(minLength: 0)
                    Image(systemName: "flame.fill")
                    Text(entry.bestStreak, format: .number)
                }
            }
            .font(.headline)
            .widgetAccentable()

            if entry.total == 0 {
                Text("Add a goal to get started")
                    .font(.caption)
            } else if entry.isAllDone {
                Text("All goals done today! 🎉")
                    .font(.caption)
            } else {
                Text("\(entry.achieved) of \(entry.total) done")
                    .font(.caption)
            }

            Gauge(value: entry.progress) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
        }
    }

    private var inline: some View {
        Group {
            if entry.isAllDone {
                Label("All goals done! 🎉", systemImage: "checkmark.circle.fill")
            } else {
                Label("\(entry.achieved)/\(entry.total) goals done", systemImage: "checkmark.circle")
            }
        }
    }
}

#Preview(as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    TodayEntry.sample
}
