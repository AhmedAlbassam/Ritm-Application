import SwiftUI

/// The end-of-challenge board: winner, animated podium, full ranking and team grade.
struct ResultsBoardView: View {
    let challenge: Challenge
    let meID: String

    @Environment(\.dismiss) private var dismiss
    @State private var showPodium = false
    @State private var showDetails = false
    @State private var crownBounce = 0
    @State private var confetti = 0

    private var board: [LeaderboardEntry] { challenge.leaderboard() }
    private var winners: [LeaderboardEntry] { challenge.winners() }
    private var isDraw: Bool { winners.count > 1 }
    private var iWon: Bool { winners.contains { $0.id == meID } && !isDraw }

    private var headline: String {
        if winners.isEmpty { return String(localized: "No winner this time") }
        if isDraw { return String(localized: "It's a draw!") }
        if iWon { return String(localized: "You won! 🎉") }
        return String(localized: "\(winners[0].member.name) wins!")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.10, blue: 0.40), Color(red: 0.36, green: 0.16, blue: 0.62), challenge.category.color.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SunburstView(color: .white, rayCount: 18, length: 700)
                .opacity(0.35)
                .offset(y: -160)

            ConfettiView(trigger: confetti)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 6) {
                        Text("Results are in!")
                            .font(.subheadline.weight(.heavy))
                            .textCase(.uppercase)
                            .tracking(2)
                            .opacity(0.8)
                        Text(headline)
                            .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                            .multilineTextAlignment(.center)
                        Text(challenge.title)
                            .font(.headline)
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 50)

                    podium
                        .frame(height: 280)

                    if showDetails {
                        VStack(spacing: 14) {
                            if board.count > 3 {
                                restOfBoard
                            }
                            if challenge.type == .group {
                                TeamGradeCard(rate: challenge.groupRate())
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        VStack(spacing: 12) {
                            ShareCardButton(content: shareContent) {
                                Label("Share Results", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundStyle(.indigo)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.white, in: Capsule())
                            }
                            Button {
                                dismiss()
                            } label: {
                                Text("Close")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(.white.opacity(0.18), in: Capsule())
                            }
                            .buttonStyle(PressableButtonStyle(scale: 0.97))
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sensoryFeedback(.success, trigger: showPodium)
        .task { await playEntrance() }
    }

    // MARK: Podium

    private var podium: some View {
        // Order: 2nd, 1st, 3rd
        let top = Array(board.prefix(3))
        let order: [Int] = top.count == 3 ? [1, 0, 2] : (top.count == 2 ? [1, 0] : [0])
        let heights: [CGFloat] = [150, 110, 80]

        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(order, id: \.self) { index in
                if index < top.count {
                    let entry = top[index]
                    let isFirst = entry.rank == 1
                    VStack(spacing: 8) {
                        ZStack(alignment: .top) {
                            AvatarView(name: entry.member.name, id: entry.member.id, size: isFirst ? 76 : 58)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            if isFirst {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                    .offset(y: -30)
                                    .symbolEffect(.bounce, value: crownBounce)
                            }
                        }
                        Text(entry.id == meID ? String(localized: "You") : entry.member.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(entry.completed.daysLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))

                        ZStack(alignment: .top) {
                            UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14, style: .continuous)
                                .fill(LinearGradient(
                                    colors: podiumColors(rank: entry.rank),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                            VStack(spacing: 4) {
                                Text(entry.rank, format: .number)
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                GradeChip(grade: entry.grade)
                            }
                            .foregroundStyle(.white)
                            .padding(.top, 10)
                        }
                        .frame(height: showPodium ? heights[min(entry.rank, 3) - 1] : 0)
                        .clipped()
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(showPodium ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(delay(for: entry.rank)), value: showPodium)
                }
            }
        }
    }

    private func delay(for rank: Int) -> Double {
        switch rank {
        case 1: 0.6
        case 2: 0.3
        default: 0
        }
    }

    private func podiumColors(rank: Int) -> [Color] {
        switch rank {
        case 1: [Color(red: 1.0, green: 0.80, blue: 0.25), Color(red: 0.95, green: 0.55, blue: 0.10)]
        case 2: [Color(red: 0.85, green: 0.87, blue: 0.92), Color(red: 0.60, green: 0.64, blue: 0.72)]
        default: [Color(red: 0.90, green: 0.60, blue: 0.35), Color(red: 0.70, green: 0.40, blue: 0.20)]
        }
    }

    private var restOfBoard: some View {
        VStack(spacing: 10) {
            ForEach(board.dropFirst(3)) { entry in
                HStack(spacing: 12) {
                    Text("#\(entry.rank)")
                        .font(.subheadline.weight(.heavy))
                        .frame(width: 36)
                    AvatarView(name: entry.member.name, id: entry.member.id, size: 34)
                    Text(entry.id == meID ? String(localized: "You") : entry.member.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(entry.completed.daysLabel)
                        .font(.caption.weight(.semibold))
                    GradeChip(grade: entry.grade)
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var shareContent: ShareCardContent {
        let grade = Grade(rate: challenge.groupRate())
        let message = challenge.type == .group
            ? String(localized: "Team grade \(grade.rawValue) · \(challenge.groupRate().formatted(.percent.precision(.fractionLength(0))))")
            : (winners.first.map { String(localized: "\($0.member.name): \($0.completed.daysLabel)") } ?? "")
        return ShareCardContent(
            headline: String(localized: "Challenge Results"),
            title: headline,
            message: "\(challenge.title) · \(message)",
            icon: "trophy.fill",
            colors: [.orange, .pink],
            ringColors: AchievementTier.gold.ringColors,
            footnote: nil,
            shareText: String(localized: "\(headline) “\(challenge.title)” on Ritm 🏆")
        )
    }

    @MainActor
    private func playEntrance() async {
        try? await Task.sleep(for: .milliseconds(250))
        showPodium = true
        try? await Task.sleep(for: .milliseconds(1100))
        crownBounce += 1
        confetti += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showDetails = true }
    }
}
