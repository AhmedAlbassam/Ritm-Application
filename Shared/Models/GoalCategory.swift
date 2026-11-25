import SwiftUI

/// The area of life a goal belongs to. Each category has its own SF Symbol and accent color.
enum GoalCategory: String, CaseIterable, Codable, Identifiable {
    case health
    case work
    case habits
    case learning
    case finance
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health: String(localized: "Health")
        case .work: String(localized: "Work")
        case .habits: String(localized: "Habits")
        case .learning: String(localized: "Learning")
        case .finance: String(localized: "Finance")
        case .personal: String(localized: "Personal")
        }
    }

    var icon: String {
        switch self {
        case .health: "heart.fill"
        case .work: "briefcase.fill"
        case .habits: "arrow.triangle.2.circlepath"
        case .learning: "book.fill"
        case .finance: "dollarsign.circle.fill"
        case .personal: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .health: .pink
        case .work: .blue
        case .habits: .purple
        case .learning: .orange
        case .finance: .green
        case .personal: .teal
        }
    }

    /// Short, upbeat title used for the reminder notification.
    var reminderTitle: String {
        switch self {
        case .health: String(localized: "Health check-in 💪")
        case .work: String(localized: "Work focus 🎯")
        case .habits: String(localized: "Habit time 🔁")
        case .learning: String(localized: "Keep learning 📚")
        case .finance: String(localized: "Money moment 💰")
        case .personal: String(localized: "Personal growth ✨")
        }
    }
}
