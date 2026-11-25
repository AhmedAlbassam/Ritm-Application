import Foundation
import Observation
import SwiftData

/// Owns the app's ModelContainer. When a widget checks off a goal in its own
/// process, the app reloads the container on returning to the foreground so the
/// UI shows the latest data.
@MainActor
@Observable
final class DataStore {
    private(set) var container: ModelContainer
    /// Changes whenever the container is replaced; used to rebuild the view tree.
    private(set) var generation = 0

    @ObservationIgnored private var loadedAt = Date.now.timeIntervalSince1970

    init() {
        container = Self.makeContainer()
    }

    func reloadIfChangedExternally() {
        guard SharedStore.lastExternalChange > loadedAt else { return }
        container = Self.makeContainer()
        loadedAt = Date.now.timeIntervalSince1970
        generation += 1
        NotificationManager.shared.configure(with: container)
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try SharedStore.makeContainer()
        } catch {
            fatalError("Failed to create the SwiftData container: \(error)")
        }
    }
}
