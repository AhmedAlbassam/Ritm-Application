import SwiftData
import SwiftUI

enum RootTab: String {
    case today, challenges, friends, insights, achievements
}

/// Tab bar + the full-screen celebration layer above everything.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(DataStore.self) private var store
    @Environment(CelebrationCenter.self) private var celebrations
    @Environment(SessionStore.self) private var session

    @SceneStorage("selectedTab") private var selectedTab: RootTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
                .tag(RootTab.today)

            ChallengesView()
                .tabItem { Label("Challenges", systemImage: "flag.2.crossed.fill") }
                .tag(RootTab.challenges)
                .badge(invitationCount)

            FriendsView()
                .tabItem { Label("Friends", systemImage: "person.2.fill") }
                .tag(RootTab.friends)
                .badge(session.incomingRequests.count)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
                .tag(RootTab.insights)

            AchievementsView()
                .tabItem { Label("Achievements", systemImage: "trophy.fill") }
                .tag(RootTab.achievements)
        }
        .tint(.indigo)
        .overlay {
            if let celebration = celebrations.current {
                CelebrationOverlay(celebration: celebration) {
                    celebrations.dismissCurrent()
                }
                .id(celebration.id)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: celebrations.current?.id)
        .overlay(alignment: .top) {
            if let name = session.welcomeName {
                WelcomeBanner(name: name)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(.spring) { session.welcomeName = nil }
                    }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: session.welcomeName)
        .alert(
            "Something went wrong",
            isPresented: Binding(get: { session.errorMessage != nil }, set: { if !$0 { session.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(session.errorMessage ?? "")
        }
        .task {
            celebrations.evaluate(in: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // Picks up check-ins made from widgets while the app was in the background.
            store.reloadIfChangedExternally()
            celebrations.evaluate(in: modelContext)
            Task { await session.refresh() }
        }
    }

    private var invitationCount: Int {
        guard let me = session.user?.id else { return 0 }
        return session.challenges.filter { $0.member(me)?.state == .invited && $0.phase() != .finished }.count
    }
}

private struct WelcomeBanner: View {
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            Text("👋")
                .font(.title2)
            VStack(alignment: .leading, spacing: 1) {
                Text("Welcome, \(name)!")
                    .font(.subheadline.weight(.bold))
                Text("Let's keep the rhythm going.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
    }
}

#if DEBUG
#Preview {
    RootView()
        .modelContainer(PreviewData.container)
        .environment(DataStore())
        .environment(SessionStore())
        .environment(NotificationManager.shared)
        .environment(CelebrationCenter.shared)
}
#endif
