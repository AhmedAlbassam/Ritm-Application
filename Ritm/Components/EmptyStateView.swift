import SwiftUI

/// Shown on the Today screen before any goals exist.
struct EmptyStateView: View {
    let onCreate: () -> Void
    let onSelectTemplate: (GoalTemplate) -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.indigo.opacity(0.15), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                Image(systemName: "target")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(LinearGradient.brand)
                    .symbolEffect(.pulse)
            }

            VStack(spacing: 8) {
                Text("Set Your First Goal")
                    .font(.title2.weight(.bold))
                Text("Small daily wins add up. Choose a goal, pick how many days, and get a friendly nudge every day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)

            Button(action: onCreate) {
                Label("Create a Goal", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.indigo)

            VStack(alignment: .leading, spacing: 10) {
                Text("Or start with an idea")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                ForEach(GoalTemplate.suggestions) { template in
                    Button {
                        onSelectTemplate(template)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: template.category.icon)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(template.category.color)
                                .frame(width: 34, height: 34)
                                .background(template.category.color.opacity(0.14), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("\(template.category.title) · \(template.targetDays) days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(template.category.color)
                        }
                        .padding(12)
                        .cardStyle(cornerRadius: 16)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.97))
                }
            }
        }
        .padding(.top, 24)
    }
}
