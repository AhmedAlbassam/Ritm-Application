import SwiftUI

/// Gradient card summarizing today's overall progress.
struct DailySummaryCard: View {
    let achieved: Int
    let total: Int

    private var progress: Double {
        total == 0 ? 0 : Double(achieved) / Double(total)
    }

    private var headline: String {
        guard total > 0 else { return "All challenges complete" }
        return "\(achieved) of \(total) \(total == 1 ? "goal" : "goals") achieved today"
    }

    private var message: String {
        if total == 0 { return "Time to set a new goal! 🚀" }
        if progress >= 1 { return "Perfect day — every goal checked off! 🎉" }
        if progress >= 0.5 { return "Great momentum. Keep it going!" }
        if progress > 0 { return "Nice start. One step at a time." }
        return "Let's make today count. 💪"
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(
                    progress: progress,
                    lineWidth: 11,
                    colors: [.white.opacity(0.7), .white],
                    trackColor: .white.opacity(0.2)
                )
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .contentTransition(.numericText())
            }
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 5) {
                Text("Today's Progress")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .opacity(0.8)
                Text(headline)
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText())
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.subheadline)
                    .opacity(0.9)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .indigo.opacity(0.3), radius: 16, y: 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: achieved)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: total)
        .accessibilityElement(children: .combine)
    }
}
