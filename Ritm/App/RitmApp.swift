import SwiftData
import SwiftUI

@main
struct RitmApp: App {
    @State private var store: DataStore

    init() {
        let store = DataStore()
        _store = State(initialValue: store)
        // Set the notification delegate as early as possible so taps on and
        // actions from reminders are handled even on a cold launch.
        NotificationManager.shared.configure(with: store.container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .id(store.generation)
                .modelContainer(store.container)
                .environment(store)
                .environment(NotificationManager.shared)
                .environment(CelebrationCenter.shared)
        }
    }
}
