import Combine
import SwiftData
import SwiftUI

/// Full progress, statistics and check-in history for a single goal.
struct GoalDetailView: View {
    let goal: Goal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notifications

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var today = Date.now.startOfDay

    var body: some View {
        Group {
            // Guard against rendering a model that was just deleted.
            if goal.isDeleted || goal.modelContext == nil {
                ContentUnavailableView("Goal Removed", systemImage: "trash")
            } else {
                content
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            today = Date.now.startOfDay
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                if !goal.isArchived {
                    todayButton
                }
                statsGrid
                HistoryGridView(goal: goal, today: today) { date in
                    toggle(date)
                }
                detailsCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(goal.category.title)
        .toolbar { toolbarMenu }
        .sheet(isPresented: $isEditing) {
            AddEditGoalView(goal: goal)
        }
        .confirmationDialog("Delete this goal?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Goal", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes “\(goal.title)” and its entire check-in history.")
        }
    }

    // MARK: Sections

    private var heroCard: some View {
        let color = goal.category.color

        return VStack(spacing: 16) {
            HStack {
                CategoryBadge(category: goal.category)
                if goal.isArchived {
                    Label("Archived", systemImage: "archivebox.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StreakBadge(streak: goal.streak(asOf: today))
            }

            ZStack {
                ProgressRing(progress: goal.progressRatio, lineWidth: 16, colors: [color.opacity(0.55), color])
                VStack(spacing: 2) {
                    Text("\(Int((goal.progressRatio * 100).rounded()))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("\(goal.displayedCompletedDays) of \(goal.targetDays) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(width: 176, height: 176)
            .padding(.vertical, 4)

            Text(goal.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            if goal.isChallengeComplete {
                Label("Challenge complete — amazing work!", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.14), in: Capsule())
            } else {
                Text("\(goal.remainingDays.daysLabel) to go")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: goal.completedDaysCount)
    }

    private var todayButton: some View {
        let achieved = goal.isAchieved(on: today)
        let color = goal.category.color

        return Button {
            toggle(today)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: achieved ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .symbolEffect(.bounce, value: achieved)
                Text(achieved ? "Achieved Today" : "Mark Today as Achieved")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(achieved ? Color.white : color)
            .background(
                achieved ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.12)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .sensoryFeedback(trigger: achieved) { _, newValue in
            newValue ? .success : .impact(weight: .light)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: achieved)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(icon: "flame.fill", title: "Current Streak", value: goal.streak(asOf: today).daysLabel, color: .orange)
            StatTile(icon: "trophy.fill", title: "Best Streak", value: goal.longestStreak.daysLabel, color: .yellow)
            StatTile(icon: "checkmark.seal.fill", title: "Days Achieved", value: "\(goal.completedDaysCount)", color: .green)
            StatTile(
                icon: "chart.line.uptrend.xyaxis",
                title: "Success Rate",
                value: "\(Int((goal.successRate(asOf: today) * 100).rounded()))%",
                color: .blue
            )
        }
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "flag.fill", title: "Started", value: goal.startDate.formatted(date: .abbreviated, time: .omitted))
            Divider().padding(.leading, 44)
            detailRow(icon: "flag.checkered", title: "Planned finish", value: goal.plannedEndDate.formatted(date: .abbreviated, time: .omitted))
            Divider().padding(.leading, 44)
            detailRow(
                icon: goal.reminderEnabled ? "bell.fill" : "bell.slash.fill",
                title: "Daily reminder",
                value: goal.reminderEnabled ? goal.reminderTime.formatted(date: .omitted, time: .shortened) : "Off"
            )
        }
        .padding(.vertical, 4)
        .cardStyle(cornerRadius: 18)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(goal.category.color)
                .frame(width: 20)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ToolbarContentBuilder
    private var toolbarMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit Goal", systemImage: "pencil")
                }
                Button {
                    toggleArchive()
                } label: {
                    Label(goal.isArchived ? "Restore Goal" : "Archive Goal",
                          systemImage: goal.isArchived ? "tray.and.arrow.up" : "archivebox")
                }
                Divider()
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Delete Goal", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Goal options")
        }
    }

    // MARK: Actions

    private func toggle(_ date: Date) {
        today = Date.now.startOfDay
        guard goal.canLog(on: date, today: today) else { return }

        let wasComplete = goal.isChallengeComplete
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            goal.toggleAchieved(on: date)
        }
        if wasComplete != goal.isChallengeComplete {
            Task { await notifications.scheduleReminder(for: goal, requestPermissionIfNeeded: false) }
        }
    }

    private func toggleArchive() {
        goal.isArchived.toggle()
        try? modelContext.save()

        if goal.isArchived {
            notifications.cancelReminder(for: goal.id)
            dismiss()
        } else {
            Task { await notifications.scheduleReminder(for: goal, requestPermissionIfNeeded: false) }
        }
    }

    private func delete() {
        notifications.cancelReminder(for: goal.id)
        modelContext.delete(goal) // cascades to all DailyLogs
        try? modelContext.save()
        dismiss()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GoalDetailView(goal: PreviewData.sampleGoal)
    }
    .modelContainer(PreviewData.container)
    .environment(NotificationManager.shared)
}
#endif
