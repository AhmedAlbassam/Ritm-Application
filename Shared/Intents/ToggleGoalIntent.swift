import AppIntents
import SwiftData
import WidgetKit

/// Checks a goal off (or un-checks it) for today. Used by the interactive widget buttons.
struct ToggleGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Goal"
    static var description = IntentDescription("Marks a goal as achieved, or not achieved, for today.")
    static var isDiscoverable: Bool = false

    @Parameter(title: "Goal ID")
    var goalID: String

    init() {}

    init(goalID: UUID) {
        self.goalID = goalID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: goalID),
              let container = SharedStore.sharedContainer
        else { return .result() }

        let context = container.mainContext
        var descriptor = FetchDescriptor<Goal>(predicate: #Predicate<Goal> { $0.id == id })
        descriptor.fetchLimit = 1

        if let goal = try context.fetch(descriptor).first {
            goal.toggleAchieved(on: .now)
            try context.save()
            SharedStore.markExternalChange()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
