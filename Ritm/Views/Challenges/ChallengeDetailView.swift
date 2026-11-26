import SwiftUI

/// Live standings for one challenge, today's check-in, and the results once it ends.
struct ChallengeDetailView: View {
    let challengeID: String

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var showResults = false
    @State private var confirmLeave = false

    @AppStorage("seenChallengeResults") private var seenResults = ""

    private var meID: String { session.user?.id ?? "" }

    var body: some View {
        Group {
            if let challenge = session.challenge(id: challengeID) {
                content(challenge)
            } else {
                ContentUnavailableView("Challenge not found", systemImage: "questionmark.circle")
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ challenge: Challenge) -> some View {
        let today = Date.now
        let phase = challenge.phase(today: today)
        let board = challenge.leaderboard(today: today)
        let checkedToday = challenge.member(meID)?.checkIns.contains(DayKey.string(from: today)) ?? false
        let waiting = challenge.members.filter { $0.state == .invited }

        return ScrollView {
            VStack(spacing: 16) {
                hero(challenge, phase: phase)

                if phase == .active, challenge.member(meID)?.state == .joined {
                    checkInButton(challenge, checkedToday: checkedToday)
                }

                if phase == .finished {
                    Button {
                        showResults = true
                    } label: {
                        Label("View Results", systemImage: "trophy.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing), in: Capsule())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.97))
                }

                if challenge.type == .oneVsOne, board.count == 2 {
                    VersusCard(challenge: challenge, board: board, meID: meID)
                } else {
                    LeaderboardCard(board: board, meID: meID, color: challenge.category.color)
                }

                if challenge.type == .group, phase != .upcoming {
                    TeamGradeCard(rate: challenge.groupRate(today: today))
                }

                if !waiting.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "hourglass")
                            .foregroundStyle(.secondary)
                        Text("Waiting for \(waiting.map(\.name).formatted(.list(type: .and)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(16)
                    .cardStyle(cornerRadius: 18)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .refreshable { await session.refresh() }
        .navigationTitle(challenge.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareCardButton(content: shareContent(challenge, board: board, phase: phase)) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        confirmLeave = true
                    } label: {
                        if challenge.creatorID == meID {
                            Label("Delete Challenge", systemImage: "trash")
                        } else {
                            Label("Leave Challenge", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            challenge.creatorID == meID ? Text("Delete this challenge for everyone?") : Text("Leave this challenge?"),
            isPresented: $confirmLeave,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                Task {
                    if await session.perform({ try await $0.leaveChallenge(challenge) }) { dismiss() }
                }
            } label: {
                challenge.creatorID == meID ? Text("Delete") : Text("Leave")
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showResults) {
            ResultsBoardView(challenge: challenge, meID: meID)
        }
        .task {
            // Show the results board automatically the first time a finished challenge is opened.
            if phase == .finished, !seenResults.contains(challenge.id) {
                seenResults += challenge.id + ","
                try? await Task.sleep(for: .milliseconds(400))
                showResults = true
            }
        }
    }

    // MARK: Pieces

    private func hero(_ challenge: Challenge, phase: Challenge.Phase) -> some View {
        let color = challenge.category.color
        let today = Date.now
        return VStack(spacing: 14) {
            HStack {
                Label(challenge.type.title, systemImage: challenge.type.icon)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2), in: Capsule())
                Spacer()
                Label(challenge.category.title, systemImage: challenge.category.icon)
                    .font(.caption.weight(.bold))
            }

            ZStack {
                ProgressRing(
                    progress: phase == .upcoming ? 0 : Double(challenge.dayNumber(today: today)) / Double(challenge.durationDays),
                    lineWidth: 12,
                    colors: [.white.opacity(0.7), .white],
                    trackColor: .white.opacity(0.2)
                )
                VStack(spacing: 2) {
                    switch phase {
                    case .upcoming:
                        Image(systemName: "calendar")
                            .font(.title.weight(.bold))
                        Text("Starts \(challenge.startDate.formatted(.dateTime.weekday(.abbreviated)))")
                            .font(.caption.weight(.semibold))
                    case .active:
                        Text("Day")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .opacity(0.8)
                        Text(challenge.dayNumber(today: today), format: .number)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                        Text("of \(challenge.durationDays)")
                            .font(.caption.weight(.semibold))
                            .opacity(0.8)
                    case .finished:
                        Image(systemName: "flag.checkered")
                            .font(.title.weight(.bold))
                        Text("Finished")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
            .frame(width: 130, height: 130)

            Text(challenge.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("\(challenge.startDate.formatted(.dateTime.month(.abbreviated).day())) – \(challenge.endDate.formatted(.dateTime.month(.abbreviated).day()))")
                .font(.subheadline.weight(.medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [color, color.opacity(0.65), .indigo.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .shadow(color: color.opacity(0.35), radius: 16, y: 8)
    }

    private func checkInButton(_ challenge: Challenge, checkedToday: Bool) -> some View {
        let color = challenge.category.color
        return Button {
            Task { await session.setCheckIn(challenge, done: !checkedToday) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: checkedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .symbolEffect(.bounce, value: checkedToday)
                (checkedToday ? Text("Done for today!") : Text("Check in for today"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(checkedToday ? Color.white : color)
            .background(
                checkedToday ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.12)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .sensoryFeedback(trigger: checkedToday) { _, new in new ? .success : .impact(weight: .light) }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: checkedToday)
    }

    private func shareContent(_ challenge: Challenge, board: [LeaderboardEntry], phase: Challenge.Phase) -> ShareCardContent {
        let myEntry = board.first { $0.id == meID }
        let rankText = myEntry.map { String(localized: "I'm #\($0.rank) of \(board.count)") } ?? ""
        let headline = phase == .finished ? String(localized: "Challenge Results") : String(localized: "Challenge in Progress")
        return ShareCardContent(
            headline: headline,
            title: challenge.title,
            message: "\(challenge.type.title) · \(rankText)",
            icon: challenge.type.icon,
            colors: [challenge.category.color, .indigo],
            ringColors: AchievementTier.gold.ringColors,
            footnote: nil,
            shareText: String(localized: "I'm taking on “\(challenge.title)” with friends on Ritm. \(rankText)")
        )
    }
}

// MARK: - Leaderboard

struct LeaderboardCard: View {
    let board: [LeaderboardEntry]
    let meID: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Leaderboard", systemImage: "list.number")
                .font(.headline)

            if board.isEmpty {
                Text("No one has joined yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(board) { entry in
                HStack(spacing: 12) {
                    RankBadge(rank: entry.rank)
                    AvatarView(name: entry.member.name, id: entry.member.id, size: 38)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(entry.member.name)
                                .font(.subheadline.weight(.semibold))
                            if entry.id == meID {
                                Text("You")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.indigo, in: Capsule())
                            }
                        }
                        LinearProgressBar(progress: entry.rate, color: color, height: 6)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.completed.daysLabel)
                            .font(.caption.weight(.bold))
                        GradeChip(grade: entry.grade)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(entry.id == meID ? Color.indigo.opacity(0.08) : .clear)
                )
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 22)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: board.map(\.id))
    }
}

struct RankBadge: View {
    let rank: Int

    var body: some View {
        ZStack {
            switch rank {
            case 1: Image(systemName: "medal.fill").foregroundStyle(.yellow)
            case 2: Image(systemName: "medal.fill").foregroundStyle(.gray)
            case 3: Image(systemName: "medal.fill").foregroundStyle(.brown)
            default:
                Text(rank, format: .number)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.title3)
        .frame(width: 28)
    }
}

struct GradeChip: View {
    let grade: Grade

    var body: some View {
        Text(grade.rawValue)
            .font(.caption.weight(.heavy))
            .foregroundStyle(grade.color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(grade.color.opacity(0.15), in: Capsule())
    }
}

/// Head-to-head scoreboard for 1 vs 1 challenges.
struct VersusCard: View {
    let challenge: Challenge
    let board: [LeaderboardEntry]
    let meID: String

    var body: some View {
        // Keep "me" on the leading side.
        let ordered = board.sorted { lhs, _ in lhs.id == meID }
        let left = ordered[0]
        let right = ordered[1]
        let diff = left.completed - right.completed

        VStack(spacing: 16) {
            HStack(alignment: .center) {
                player(left, isLeading: left.completed > right.completed)
                Text("VS")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 50)
                player(right, isLeading: right.completed > left.completed)
            }

            Group {
                if diff == 0 {
                    Text("It's neck and neck!")
                } else {
                    let leader = diff > 0 ? left : right
                    Text("\(leader.member.name) leads by \(abs(diff).daysLabel)")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .cardStyle(cornerRadius: 22)
    }

    private func player(_ entry: LeaderboardEntry, isLeading: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                AvatarView(name: entry.member.name, id: entry.member.id, size: 64)
                if isLeading {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                        .offset(y: -22)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Text(entry.id == meID ? String(localized: "You") : entry.member.name)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
            Text(entry.completed, format: .number)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(challenge.category.color)
                .contentTransition(.numericText())
            Text("days")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isLeading)
    }
}

/// The whole group's letter grade.
struct TeamGradeCard: View {
    let rate: Double

    var body: some View {
        let grade = Grade(rate: rate)
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: rate, lineWidth: 9, colors: [grade.color.opacity(0.6), grade.color])
                Text(grade.rawValue)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(grade.color)
            }
            .frame(width: 74, height: 74)
            VStack(alignment: .leading, spacing: 4) {
                Text("Team Grade")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(grade.praise)
                    .font(.headline)
                Text("Average completion: \(rate.formatted(.percent.precision(.fractionLength(0))))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .cardStyle(cornerRadius: 22)
    }
}
