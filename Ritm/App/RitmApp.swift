import SwiftUI
import SwiftData

@main
struct RitmApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Goal.self, DailyLog.self)
        } catch {
            fatalError("Failed to create the SwiftData container: \(error)")
        }
        // Set the notification delegate as early as possible so taps on and
        // actions from reminders are handled even on a cold launch.
        NotificationManager.shared.configure(with: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environment(NotificationManager.shared)
        }
        .modelContainer(modelContainer)
    }
}
