import SwiftData
import SwiftUI

/// All badges (earned and still to earn), the user's level, and recent goal milestones.
struct AchievementsView: View {
    @Query(sort: \AchievementRecord.unlockedAt, order: .reverse) private var records: [AchievementRecord]
    @Query private var goals: [Goal]

    @State private var selectedAchievement: Achievement?
    @State private var selectedMilestone: AchievementRecord?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        let stats = ProgressAnalytics(goals: goals.map(GoalSnapshot.init)).achievementStats
        let recordsByKey = Dictionary(records.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        let unlocked = Achievement.allCases.filter { recordsByKey[$0.recordKey] != nil }
        let milestones = records.filter(\.isMilestone)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    LevelHeaderCard(unlocked: unlocked)

                    if !milestones.isEmpty {
                        milestoneSection(milestones)
                    }

                    ForEach(AchievementGroup.allCases, id: \.self) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.title)
                                .font(.title3.weight(.bold))
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(Achievement.allCases.filter { $0.group == group }) { achievement in
                                    BadgeTile(
                                        achievement: achievement,
                                        isUnlocked: recordsByKey[achievement.recordKey] != nil,
                                        progress: Double(min(achievement.currentValue(in: stats), achievement.target)) / Double(achievement.target)
                                    ) {
                                        selectedAchievement = achievement
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Achievements")
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(
                    achievement: achievement,
                    unlockedAt: recordsByKey[achievement.recordKey]?.unlockedAt,
                    currentValue: achievement.currentValue(in: stats)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedMilestone) { record in
                MilestoneShareSheet(record: record)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func milestoneSection(_ milestones: [AchievementRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Milestones")
                .font(.title3.weight(.bold))
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(milestones.prefix(12)) { record in
                        Button {
                            selectedMilestone = record
                        } label: {
                            MilestoneCard(record: record)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.96))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)
        }
    }
}

// MARK: - Pieces

private struct LevelHeaderCard: View {
    let unlocked: [Achievement]

    private var points: Int { unlocked.reduce(0) { $0 + $1.tier.points } }
    private var level: Int { points / 100 + 1 }
    private var levelProgress: Double { Double(points % 100) / 100 }

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: levelProgress, lineWidth: 10, colors: [.yellow.opacity(0.8), .yellow], trackColor: .white.opacity(0.2))
                VStack(spacing: 0) {
                    Text("Level")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .opacity(0.8)
                    Text(level, format: .number)
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .contentTransition(.numericText())
                }
            }
            .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(unlocked.count) of \(Achievement.allCases.count) badges")
                    .font(.title3.weight(.bold))
                Label {
                    Text("\(points) points")
                } icon: {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                }
                .font(.subheadline.weight(.semibold))
                Text("\(100 - points % 100) points to the next level")
                    .font(.caption)
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .indigo.opacity(0.3), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

private struct BadgeTile: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                BadgeView(achievement: achievement, size: 72, isLocked: !isUnlocked)
                Text(achievement.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isUnlocked ? Color.primary : Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .top)
                if !isUnlocked {
                    LinearProgressBar(progress: progress, color: achievement.colors.first ?? .indigo, height: 4)
                        .frame(width: 56)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .cardStyle(cornerRadius: 18)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
        .accessibilityLabel(Text(achievement.title))
        .accessibilityValue(isUnlocked ? Text("Unlocked") : Text("Locked"))
    }
}

private struct MilestoneCard: View {
    let record: AchievementRecord

    private var milestone: GoalMilestone { GoalMilestone(rawValue: record.value) ?? .half }
    private var category: GoalCategory { GoalCategory(rawValue: record.categoryRawValue ?? "") ?? .personal }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: milestone.icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(category.color.gradient, in: Circle())
                Spacer()
                Text(Double(record.value) / 100, format: .percent)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(category.color)
            }
            Text(milestone.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
            Text(record.goalTitle ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(record.unlockedAt, format: .dateTime.month(.abbreviated).day())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 150, alignment: .leading)
        .padding(14)
        .cardStyle(cornerRadius: 18)
    }
}

// MARK: - Sheets

struct AchievementDetailSheet: View {
    let achievement: Achievement
    let unlockedAt: Date?
    let currentValue: Int

    private var isUnlocked: Bool { unlockedAt != nil }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                if isUnlocked {
                    SunburstView(color: achievement.colors.first ?? .orange, rayCount: 14, length: 260)
                }
                BadgeView(achievement: achievement, size: 130, isLocked: !isUnlocked, animated: isUnlocked)
            }
            .frame(height: 180)
            .padding(.top, 24)

            Text(achievement.tier.title)
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(colors: achievement.tier.ringColors, startPoint: .leading, endPoint: .trailing).opacity(0.35),
                    in: Capsule()
                )

            VStack(spacing: 6) {
                Text(achievement.title)
                    .font(.title2.weight(.bold))
                Text(achievement.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            if let unlockedAt {
                Label {
                    Text("Unlocked on \(unlockedAt.formatted(date: .long, time: .omitted))")
                } icon: {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
                .font(.subheadline.weight(.medium))

                ShareCardButton(content: ShareCardContent(celebration: .achievement(achievement, date: unlockedAt))) {
                    Label("Share with Friends", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: achievement.colors, startPoint: .leading, endPoint: .trailing), in: Capsule())
                }
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 8) {
                    LinearProgressBar(
                        progress: Double(min(currentValue, achievement.target)) / Double(achievement.target),
                        color: achievement.colors.first ?? .indigo,
                        height: 10
                    )
                    Text("\(min(currentValue, achievement.target)) / \(achievement.target)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 40)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MilestoneShareSheet: View {
    let record: AchievementRecord
    @Environment(\.dismiss) private var dismiss

    private var content: ShareCardContent {
        let milestone = GoalMilestone(rawValue: record.value) ?? .half
        let category = GoalCategory(rawValue: record.categoryRawValue ?? "") ?? .personal
        let goalTitle = record.goalTitle ?? ""
        let percent = (Double(record.value) / 100).formatted(.percent)
        return ShareCardContent(
            headline: String(localized: "Milestone Reached!"),
            title: milestone.title,
            message: String(localized: "\(percent) of “\(goalTitle)” complete"),
            icon: milestone.icon,
            colors: [category.color, category.color.opacity(0.7)],
            ringColors: milestone == .complete ? AchievementTier.gold.ringColors : [.white.opacity(0.9), .white.opacity(0.6)],
            footnote: record.unlockedAt.formatted(date: .long, time: .omitted),
            shareText: "\(milestone.title) \(goalTitle) #Ritm"
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ShareCardView(content: content)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    .scaleEffect(0.85)
                    .frame(height: ShareCardView.size.height * 0.85)

                ShareCardButton(content: content) {
                    Label("Share with Friends", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient.brand, in: Capsule())
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 8)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    AchievementsView()
        .modelContainer(PreviewData.container)
}
#endif
