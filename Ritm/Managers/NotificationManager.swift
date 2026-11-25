import Foundation
import Observation
import SwiftData
import UIKit
import UserNotifications

enum ReminderConstants {
    static let categoryIdentifier = "GOAL_REMINDER"
    static let markAchievedAction = "MARK_ACHIEVED"
    static let goalIDKey = "goalID"
    static let identifierPrefix = "goal-reminder-"

    static func identifier(for goalID: UUID) -> String {
        identifierPrefix + goalID.uuidString
    }
}

/// Owns everything related to local reminder notifications:
/// permission, scheduling, updating, cancelling and handling actions.
@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private let delegate = NotificationDelegate()
    @ObservationIgnored private var modelContainer: ModelContainer?

    private init() {}

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    var isDenied: Bool { authorizationStatus == .denied }

    // MARK: Setup

    func configure(with container: ModelContainer) {
        modelContainer = container
        center.delegate = delegate

        let markAchieved = UNNotificationAction(
            identifier: ReminderConstants.markAchievedAction,
            title: String(localized: "Mark as Achieved ✅"),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: ReminderConstants.categoryIdentifier,
            actions: [markAchieved],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])

        Task { await refreshAuthorizationStatus() }
    }

    // MARK: Permission

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Asks for permission only if the user hasn't decided yet.
    /// Returns whether notifications can be delivered.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        guard authorizationStatus == .notDetermined else { return isAuthorized }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Scheduling

    /// Schedules (or replaces) the repeating daily reminder for a goal.
    /// Removes it when the reminder is off, the goal is archived, or the challenge is complete.
    func scheduleReminder(for goal: Goal, requestPermissionIfNeeded: Bool = true) async {
        // Snapshot the model before any suspension point.
        let goalID = goal.id
        let identifier = ReminderConstants.identifier(for: goalID)
        let shouldSchedule = goal.reminderEnabled && !goal.isArchived && !goal.isChallengeComplete
        let category = goal.category
        let message = goal.reminderMessage
        let time = goal.reminderTime

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard shouldSchedule else { return }

        let allowed: Bool
        if requestPermissionIfNeeded {
            allowed = await requestAuthorizationIfNeeded()
        } else {
            await refreshAuthorizationStatus()
            allowed = isAuthorized
        }
        guard allowed else { return }

        let content = UNMutableNotificationContent()
        content.title = category.reminderTitle
        content.body = message
        content.sound = .default
        content.categoryIdentifier = ReminderConstants.categoryIdentifier
        content.threadIdentifier = category.rawValue
        content.userInfo = [ReminderConstants.goalIDKey: goalID.uuidString]

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            print("⚠️ Failed to schedule reminder for \(goalID): \(error)")
        }
    }

    /// Same as `scheduleReminder` — scheduling with an existing identifier replaces it.
    func updateReminder(for goal: Goal) async {
        await scheduleReminder(for: goal)
    }

    func cancelReminder(for goalID: UUID) {
        let identifier = ReminderConstants.identifier(for: goalID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    /// Brings pending notifications in line with the stored goals (e.g. on launch).
    /// Never prompts for permission.
    func syncReminders(for goals: [Goal]) async {
        let validIdentifiers = Set(
            goals
                .filter { $0.reminderEnabled && !$0.isArchived && !$0.isChallengeComplete }
                .map { ReminderConstants.identifier(for: $0.id) }
        )
        let pending = await center.pendingNotificationRequests().map(\.identifier)
        let orphaned = pending.filter {
            $0.hasPrefix(ReminderConstants.identifierPrefix) && !validIdentifiers.contains($0)
        }
        center.removePendingNotificationRequests(withIdentifiers: orphaned)

        for goal in goals where !goal.isDeleted {
            await scheduleReminder(for: goal, requestPermissionIfNeeded: false)
        }
    }

    // MARK: Actions

    /// Handles the "Mark as Achieved" notification action.
    func markGoalAchievedToday(_ goalID: UUID) {
        guard let context = modelContainer?.mainContext else { return }
        var descriptor = FetchDescriptor<Goal>(predicate: #Predicate<Goal> { $0.id == goalID })
        descriptor.fetchLimit = 1
        guard let goal = try? context.fetch(descriptor).first else { return }

        goal.setAchieved(true, on: .now)
        AppEvents.goalsDidChange(in: context)

        if goal.isChallengeComplete {
            cancelReminder(for: goal.id)
        }
    }
}

// MARK: - Delegate

private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// Show reminders as banners even when the app is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == ReminderConstants.markAchievedAction,
              let idString = response.notification.request.content.userInfo[ReminderConstants.goalIDKey] as? String,
              let goalID = UUID(uuidString: idString)
        else { return }

        await NotificationManager.shared.markGoalAchievedToday(goalID)
    }
}
