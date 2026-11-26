import SwiftData
import SwiftUI

@main
struct RitmApp: App {
    @State private var store: DataStore
    @State private var session = SessionStore()

    init() {
        // Connects to Firebase when GoogleService-Info.plist is in the app (see README).
        FirebaseSetup.configureIfPossible()

        let store = DataStore()
        _store = State(initialValue: store)
        // Set the notification delegate as early as possible so taps on and
        // actions from reminders are handled even on a cold launch.
        NotificationManager.shared.configure(with: store.container)
    }

    var body: some Scene {
        WindowGroup {
            AppGate()
                .id(store.generation)
                .modelContainer(store.container)
                .environment(store)
                .environment(session)
                .environment(NotificationManager.shared)
                .environment(CelebrationCenter.shared)
        }
    }
}

/// Shows the login screen until someone is signed in.
struct AppGate: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            switch session.phase {
            case .loading:
                SplashView()
                    .transition(.opacity)
            case .signedOut:
                AuthView()
                    .transition(.opacity)
            case .signedIn:
                RootView()
                    .transition(.asymmetric(insertion: .scale(scale: 1.05).combined(with: .opacity), removal: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: session.phase)
        .task { await session.restore() }
    }
}
