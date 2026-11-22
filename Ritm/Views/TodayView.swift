import Combine
import SwiftData
import SwiftUI

/// Main screen: today's summary, category filter, and the list of active goals.
struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: #Predicate<Goal> { $0.isArchived == false }, sort: \Goal.createdAt, order: .forward)
    private var goals: [Goal]

    @State private var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar { toolbarContent }
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
            }
            .sheet(item: $viewModel.addGoalRequest) { request in
                AddEditGoalView(template: request.template)
            }
            .overlay(alignment: .bottom) { celebrationToast }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            viewModel.refreshToday()
        }
        .task {
            await NotificationManager.shared.syncReminders(for: goals)
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(viewModel.today, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.top, -8)

            if goals.isEmpty {
                EmptyStateView(
                    onCreate: { viewModel.addGoalRequest = AddGoalRequest() },
                    onSelectTemplate: { viewModel.addGoalRequest = AddGoalRequest(template: $0) }
                )
            } else {
                let summary = viewModel.summary(for: goals)
                DailySummaryCard(achieved: summary.achieved, total: summary.total)

                CategoryFilterBar(
                    selection: $viewModel.selectedCategory,
                    counts: viewModel.categoryCounts(for: goals),
                    totalCount: goals.count
                )

                goalList
            }
        }
    }

    @ViewBuilder
    private var goalList: some View {
        let active = viewModel.visibleActiveGoals(from: goals)
        let completed = viewModel.visibleCompletedChallenges(from: goals)

        if active.isEmpty && completed.isEmpty {
            filteredEmptyState
        }

        if !active.isEmpty {
            LazyVStack(spacing: 12) {
                ForEach(active) { goal in
                    GoalCardView(goal: goal, today: viewModel.today) {
                        viewModel.toggle(goal)
                    }
                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                }
            }
            .animation(.snappy, value: viewModel.selectedCategory)
        }

        if !completed.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Completed Challenges", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                ForEach(completed) { goal in
                    GoalCardView(goal: goal, today: viewModel.today) {
                        viewModel.toggle(goal)
                    }
                    .opacity(0.85)
                }
            }
        }
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.selectedCategory?.icon ?? "tray")
                .font(.largeTitle)
                .foregroundStyle(viewModel.selectedCategory?.color ?? .secondary)
            Text("No \(viewModel.selectedCategory?.title ?? "") goals yet")
                .font(.headline)
            Button("Add a Goal") {
                viewModel.addGoalRequest = AddGoalRequest()
            }
            .buttonStyle(.bordered)
            .tint(viewModel.selectedCategory?.color ?? .indigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var celebrationToast: some View {
        if let message = viewModel.celebrationMessage {
            ToastBanner(message: message)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: message) {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.spring) { viewModel.celebrationMessage = nil }
                }
                .onTapGesture {
                    withAnimation(.spring) { viewModel.celebrationMessage = nil }
                }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
                ArchivedGoalsView()
            } label: {
                Image(systemName: "archivebox")
            }
            .accessibilityLabel("Archived Goals")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.addGoalRequest = AddGoalRequest()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Add Goal")
        }
    }
}

#if DEBUG
#Preview("Today") {
    TodayView()
        .modelContainer(PreviewData.container)
        .environment(NotificationManager.shared)
}

#Preview("Empty") {
    TodayView()
        .modelContainer(for: [Goal.self, DailyLog.self], inMemory: true)
        .environment(NotificationManager.shared)
}
#endif
