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

    var title: String { rawValue.capitalized }

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
        case .health: "Health check-in 💪"
        case .work: "Work focus 🎯"
        case .habits: "Habit time 🔁"
        case .learning: "Keep learning 📚"
        case .finance: "Money moment 💰"
        case .personal: "Personal growth ✨"
        }
    }
}
