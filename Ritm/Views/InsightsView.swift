import Charts
import SwiftData
import SwiftUI

/// Stats & insights: trends, consistency heatmap, categories, best weekday, per-goal performance.
struct InsightsView: View {
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @State private var range: InsightsRange = .week

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    ContentUnavailableView(
                        "No Insights Yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Create a goal and check in for a few days to see your trends here.")
                    )
                } else {
                    content(report: InsightsReport(goals: goals.map(GoalSnapshot.init), range: range))
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Insights")
        }
    }

    private func content(report: InsightsReport) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Range", selection: $range.animation(.snappy)) {
                    ForEach(InsightsRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: range)

                overviewGrid(report)

                if !report.messages.isEmpty {
                    messagesCard(report.messages)
                }

                checkInChart(report)
                heatmapCard(report)

                weekdayCard(report)

                if !report.categories.isEmpty {
                    categoryCard(report)
                }

                if !report.goalPerformance.isEmpty {
                    goalPerformanceCard(report)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Overview

    private func overviewGrid(_ report: InsightsReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(icon: "checkmark.circle.fill", title: "Check-ins", value: report.checkIns.formatted(), color: .green)
            StatTile(
                icon: "percent",
                title: "Completion Rate",
                value: report.completionRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "–",
                color: .blue
            )
            StatTile(icon: "sun.max.fill", title: "Perfect Days", value: report.perfectDays.formatted(), color: .yellow)
            StatTile(icon: "flame.fill", title: "Best Active Streak", value: report.bestCurrentStreak.daysLabel, color: .orange)
        }
    }

    private func messagesCard(_ messages: [InsightMessage]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Insights", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.indigo)
            ForEach(messages) { message in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: message.icon)
                        .foregroundStyle(message.color)
                        .frame(width: 22)
                    Text(message.text)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 20)
    }

    // MARK: Charts

    private func checkInChart(_ report: InsightsReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Check-ins")
                    .font(.headline)
                Spacer()
                if report.checkInDelta != 0 {
                    Label {
                        Text(abs(report.checkInDelta), format: .number)
                    } icon: {
                        Image(systemName: report.checkInDelta > 0 ? "arrow.up" : "arrow.down")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(report.checkInDelta > 0 ? .green : .orange)
                }
            }

            Chart(report.points) { point in
                BarMark(
                    x: .value("Date", point.date, unit: report.range == .year ? .month : .day),
                    y: .value("Check-ins", point.checkIns)
                )
                .foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .bottom, endPoint: .top))
                .cornerRadius(report.range == .month ? 3 : 6)
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues(for: report.range)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormat(for: report.range), centered: report.range != .month)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .cardStyle(cornerRadius: 20)
    }

    private func xAxisValues(for range: InsightsRange) -> AxisMarkValues {
        switch range {
        case .week: .stride(by: .day)
        case .month: .stride(by: .day, count: 7)
        case .year: .stride(by: .month)
        }
    }

    private func xAxisFormat(for range: InsightsRange) -> Date.FormatStyle {
        switch range {
        case .week: .dateTime.weekday(.abbreviated)
        case .month: .dateTime.day().month(.abbreviated)
        case .year: .dateTime.month(.narrow)
        }
    }

    private func heatmapCard(_ report: InsightsReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Consistency")
                    .font(.headline)
                Spacer()
                Text("Last 17 weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 3) {
                ForEach(Array(report.heatmapWeeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 3) {
                        ForEach(week) { cell in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(heatColor(cell.intensity))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Consistency heatmap"))

            HStack(spacing: 4) {
                Text("Less")
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(value))
                        .frame(width: 11, height: 11)
                }
                Text("More")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .cardStyle(cornerRadius: 20)
    }

    private func heatColor(_ intensity: Double?) -> Color {
        guard let intensity, intensity > 0 else {
            return Color(.systemFill).opacity(intensity == nil ? 0.4 : 1)
        }
        return Color.indigo.opacity(0.25 + 0.75 * intensity)
    }

    private func weekdayCard(_ report: InsightsReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Best Days")
                    .font(.headline)
                Spacer()
                Text("Last 12 weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(report.weekdays) { day in
                    let isBest = day.weekday == report.bestWeekday?.weekday
                    VStack(spacing: 6) {
                        Text(day.rate, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        GeometryReader { proxy in
                            VStack {
                                Spacer(minLength: 0)
                                Capsule()
                                    .fill(isBest ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.indigo.opacity(0.25)))
                                    .frame(height: max(6, proxy.size.height * day.rate))
                            }
                        }
                        .frame(height: 90)
                        Text(day.symbol)
                            .font(.caption.weight(isBest ? .bold : .regular))
                            .foregroundStyle(isBest ? Color.indigo : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .animation(.spring, value: report.weekdays.map(\.rate))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: 20)
    }

    private func categoryCard(_ report: InsightsReport) -> some View {
        let total = max(1, report.categories.reduce(0) { $0 + $1.count })
        return VStack(alignment: .leading, spacing: 12) {
            Text("Life Areas")
                .font(.headline)
            HStack(spacing: 20) {
                Chart(report.categories) { item in
                    SectorMark(
                        angle: .value("Check-ins", item.count),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.category.color)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(report.categories) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.category.icon)
                                .font(.caption)
                                .foregroundStyle(item.category.color)
                                .frame(width: 18)
                            Text(item.category.title)
                                .font(.subheadline)
                            Spacer(minLength: 4)
                            Text(Double(item.count) / Double(total), format: .percent.precision(.fractionLength(0)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 20)
    }

    private func goalPerformanceCard(_ report: InsightsReport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Goal Success Rate")
                .font(.headline)
            ForEach(report.goalPerformance) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: item.goal.category.icon)
                            .font(.caption)
                            .foregroundStyle(item.goal.category.color)
                        Text(item.goal.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Spacer()
                        Text(item.rate, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(item.goal.category.color)
                    }
                    LinearProgressBar(progress: item.rate, color: item.goal.category.color, height: 6)
                }
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 20)
    }
}

#if DEBUG
#Preview {
    InsightsView()
        .modelContainer(PreviewData.container)
}
#endif
