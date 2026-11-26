import SwiftUI

/// Invitations, active, upcoming and finished challenges with friends.
struct ChallengesView: View {
    @Environment(SessionStore.self) private var session
    @State private var isCreating = false

    private var meID: String { session.user?.id ?? "" }

    private func myState(_ challenge: Challenge) -> ChallengeMember.State? {
        challenge.member(meID)?.state
    }

    var body: some View {
        let today = Date.now
        let invitations = session.challenges.filter { myState($0) == .invited && $0.phase(today: today) != .finished }
        let joined = session.challenges.filter { myState($0) == .joined }
        let active = joined.filter { $0.phase(today: today) == .active }
        let upcoming = joined.filter { $0.phase(today: today) == .upcoming }
        let finished = joined.filter { $0.phase(today: today) == .finished }

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if invitations.isEmpty && joined.isEmpty {
                        emptyState
                    }

                    if !invitations.isEmpty {
                        section("Invitations", icon: "envelope.open.fill", color: .pink) {
                            ForEach(invitations) { challenge in
                                InvitationCard(challenge: challenge)
                            }
                        }
                    }

                    if !active.isEmpty {
                        section("Active", icon: "bolt.fill", color: .orange) {
                            ForEach(active) { challenge in
                                NavigationLink(value: challenge.id) {
                                    ChallengeCard(challenge: challenge, meID: meID)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !upcoming.isEmpty {
                        section("Starting Soon", icon: "calendar", color: .blue) {
                            ForEach(upcoming) { challenge in
                                NavigationLink(value: challenge.id) {
                                    ChallengeCard(challenge: challenge, meID: meID)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !finished.isEmpty {
                        section("Results", icon: "trophy.fill", color: .yellow) {
                            ForEach(finished) { challenge in
                                NavigationLink(value: challenge.id) {
                                    ChallengeCard(challenge: challenge, meID: meID)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Challenges")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel(Text("New Challenge"))
                }
            }
            .refreshable { await session.refresh() }
            .navigationDestination(for: String.self) { id in
                ChallengeDetailView(challengeID: id)
            }
            .sheet(isPresented: $isCreating) {
                CreateChallengeView()
            }
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange.opacity(0.2), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                Image(systemName: "figure.fencing")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .symbolEffect(.pulse)
            }
            Text("Challenge Your Friends")
                .font(.title2.weight(.bold))
            Text("Pick a habit, invite a friend for a 1 vs 1 or a whole group, and see who keeps the rhythm best.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Create a Challenge", icon: "plus") { isCreating = true }
            if session.friends.isEmpty {
                Text("Tip: add friends in the Friends tab first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}

// MARK: - Cards

struct ChallengeCard: View {
    @Environment(SessionStore.self) private var session
    let challenge: Challenge
    let meID: String

    var body: some View {
        let today = Date.now
        let phase = challenge.phase(today: today)
        let board = challenge.leaderboard(today: today)
        let myEntry = board.first { $0.id == meID }
        let checkedToday = challenge.member(meID)?.checkIns.contains(DayKey.string(from: today)) ?? false
        let color = challenge.category.color

        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: challenge.category.icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(color.gradient, in: Circle())
                    Label(challenge.type.title, systemImage: challenge.type.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                    Spacer(minLength: 0)
                    statusText(phase: phase, myEntry: myEntry, board: board)
                }

                Text(challenge.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if phase == .active {
                    VStack(alignment: .leading, spacing: 5) {
                        LinearProgressBar(progress: Double(challenge.dayNumber(today: today)) / Double(challenge.durationDays), color: color, height: 6)
                        Text("Day \(challenge.dayNumber(today: today)) of \(challenge.durationDays)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                MemberStack(members: challenge.joinedMembers)
            }

            if phase == .active {
                CheckInButton(isCompleted: checkedToday, color: color) {
                    Task { await session.setCheckIn(challenge, done: !checkedToday) }
                }
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 22)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func statusText(phase: Challenge.Phase, myEntry: LeaderboardEntry?, board: [LeaderboardEntry]) -> some View {
        switch phase {
        case .upcoming:
            let days = max(1, Calendar.current.numberOfDays(from: .now, to: challenge.startDate))
            Text("Starts in \(days.daysLabel)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
        case .active:
            if let myEntry {
                Text("#\(myEntry.rank) of \(board.count)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(myEntry.rank == 1 ? Color.orange : Color.secondary)
            }
        case .finished:
            if let myEntry, myEntry.rank == 1, myEntry.completed > 0 {
                Label("Winner", systemImage: "crown.fill")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.orange)
            } else if let myEntry {
                Text("#\(myEntry.rank) of \(board.count)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Overlapping avatars.
struct MemberStack: View {
    let members: [ChallengeMember]
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(members.prefix(5)) { member in
                AvatarView(name: member.name, id: member.id, size: size)
            }
            if members.count > 5 {
                Text("+\(members.count - 5)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
        }
    }
}

private struct InvitationCard: View {
    @Environment(SessionStore.self) private var session
    let challenge: Challenge
    @State private var isWorking = false

    private var inviterName: String {
        challenge.member(challenge.creatorID)?.name ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AvatarView(name: inviterName, id: challenge.creatorID, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(inviterName) challenged you!")
                        .font(.subheadline.weight(.bold))
                    Text(challenge.title)
                        .font(.headline)
                    Text("\(challenge.type.title) · \(challenge.durationDays.daysLabel) · starts \(challenge.startDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    respond(accept: false)
                } label: {
                    Text("Decline")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.96))

                Button {
                    respond(accept: true)
                } label: {
                    Label("Accept", systemImage: "hand.thumbsup.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(challenge.category.color.gradient, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.96))
            }
            .disabled(isWorking)
        }
        .padding(16)
        .cardStyle(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(challenge.category.color.opacity(0.4), lineWidth: 1.5)
        )
    }

    private func respond(accept: Bool) {
        isWorking = true
        Task {
            await session.perform { try await $0.respondToInvite(challenge, accept: accept) }
            isWorking = false
        }
    }
}
