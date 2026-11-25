import SwiftData
import SwiftUI

enum RootTab: String {
    case today, insights, achievements
}

/// Tab bar + the full-screen celebration layer above everything.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(DataStore.self) private var store
    @Environment(CelebrationCenter.self) private var celebrations

    @SceneStorage("selectedTab") private var selectedTab: RootTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
                .tag(RootTab.today)

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
        .task {
            celebrations.evaluate(in: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // Picks up check-ins made from widgets while the app was in the background.
            store.reloadIfChangedExternally()
            celebrations.evaluate(in: modelContext)
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .modelContainer(PreviewData.container)
        .environment(DataStore())
        .environment(NotificationManager.shared)
        .environment(CelebrationCenter.shared)
}
#endif
