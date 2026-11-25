import Foundation
import SwiftData

/// The SwiftData store shared between the app and its widgets through an App Group.
///
/// The App Group identifier comes from the `RitmAppGroupID` Info.plist key, which
/// `project.yml` fills from the `APP_GROUP_ID` build setting. If the App Group isn't
/// available (for example, signing isn't set up yet), the app falls back to its
/// private Application Support folder so it still works; the widgets then show an
/// "Open Ritm" placeholder until the App Group is configured.
enum SharedStore {
    static let appGroupID: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "RitmAppGroupID") as? String,
           !value.isEmpty, !value.contains("$(") {
            return value
        }
        return "group.com.example.Ritm"
    }()

    static let schema = Schema([Goal.self, DailyLog.self, AchievementRecord.self])

    static var groupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var isUsingAppGroup: Bool { groupContainerURL != nil }

    static var storeURL: URL {
        let directory = groupContainerURL ?? URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "Ritm.store")
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// A lazily created container for the widget extension and App Intents.
    static let sharedContainer: ModelContainer? = try? makeContainer()

    // MARK: Cross-process change signal

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static let externalChangeKey = "lastExternalChange"

    /// Called by widgets / intents after they write, so the app reloads its data.
    static func markExternalChange() {
        defaults.set(Date.now.timeIntervalSince1970, forKey: externalChangeKey)
    }

    static var lastExternalChange: TimeInterval {
        defaults.double(forKey: externalChangeKey)
    }
}
