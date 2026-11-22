import SwiftData
import SwiftUI

/// Goals the user has archived. History is kept; they can be restored or deleted.
struct ArchivedGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notifications

    @Query(filter: #Predicate<Goal> { $0.isArchived == true }, sort: \Goal.createdAt, order: .reverse)
    private var goals: [Goal]

    var body: some View {
        Group {
            if goals.isEmpty {
                ContentUnavailableView(
                    "No Archived Goals",
                    systemImage: "archivebox",
                    description: Text("Goals you archive appear here, with their full history kept safe.")
                )
            } else {
                List {
                    ForEach(goals) { goal in
                        NavigationLink(value: goal) {
                            row(for: goal)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                restore(goal)
                            } label: {
                                Label("Restore", systemImage: "tray.and.arrow.up")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(goal)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Archived")
    }

    private func row(for goal: Goal) -> some View {
        HStack(spacing: 12) {
            Image(systemName: goal.category.icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(goal.category.color)
                .frame(width: 36, height: 36)
                .background(goal.category.color.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(goal.displayedCompletedDays) / \(goal.targetDays) days\(goal.isChallengeComplete ? " · Completed 🏆" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func restore(_ goal: Goal) {
        withAnimation { goal.isArchived = false }
        try? modelContext.save()
        Task { await notifications.scheduleReminder(for: goal, requestPermissionIfNeeded: false) }
    }

    private func delete(_ goal: Goal) {
        notifications.cancelReminder(for: goal.id)
        withAnimation { modelContext.delete(goal) }
        try? modelContext.save()
    }
}
