import Foundation

/// An offline stand-in for the real backend, used by the developer-only admin login.
/// It's seeded with sample friends, requests and challenges (one finished, so the
/// results board can be seen right away) and saves its state to a local file.
/// Simulated friends accept your friend requests and challenge invites after a moment.
@MainActor
final class DemoBackend: SocialBackend {
    let isDemo = true

    private struct DemoUser: Codable {
        let id: String
        let name: String
        let email: String
        let phone: String
    }

    private struct State: Codable {
        var version: Int
        var me: UserProfile
        var directory: [DemoUser]
        var friends: [Friend]
        var incoming: [FriendRequest]
        var outgoing: [FriendRequest]
        var challenges: [Challenge]
    }

    private static let stateVersion = 1
    private static let fileURL = URL.applicationSupportDirectory.appending(path: "ritm-demo.json")

    private var state: State

    init() {
        if let data = try? Data(contentsOf: Self.fileURL),
           let saved = try? JSONDecoder().decode(State.self, from: data),
           saved.version == Self.stateVersion {
            state = saved
        } else {
            state = Self.seed()
        }
    }

    private func save() {
        try? FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    private var me: String { state.me.id }

    // MARK: Account

    func restoreSession() async -> UserProfile? { state.me }

    func signUp(_ data: SignUpData) async throws -> UserProfile { state.me }

    func signIn(email: String, password: String) async throws -> UserProfile {
        try await Task.sleep(for: .milliseconds(500))
        return state.me
    }

    func sendPasswordReset(email: String) async throws {}

    func signOut() throws {}

    /// "Deleting" the demo account resets the demo data.
    func deleteAccount() async throws {
        state = Self.seed()
        save()
    }

    // MARK: Friends

    func findUser(emailOrPhone: String) async throws -> PublicProfile? {
        try await Task.sleep(for: .milliseconds(400))
        let query = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query == state.me.email.lowercased() { throw BackendError.cannotAddYourself }
        let digits = query.filter(\.isNumber)
        let match = state.directory.first {
            $0.email.lowercased() == query || (!digits.isEmpty && $0.phone.filter(\.isNumber) == digits)
        }
        return match.map { PublicProfile(id: $0.id, name: $0.name) }
    }

    func fetchFriends() async throws -> [Friend] {
        simulateFriendActivity()
        return state.friends.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func fetchFriendRequests() async throws -> (incoming: [FriendRequest], outgoing: [FriendRequest]) {
        simulateFriendActivity()
        return (state.incoming, state.outgoing)
    }

    func sendFriendRequest(to profile: PublicProfile) async throws {
        if state.friends.contains(where: { $0.id == profile.id }) { throw BackendError.alreadyFriends }
        if state.outgoing.contains(where: { $0.toID == profile.id }) { throw BackendError.requestAlreadySent }
        state.outgoing.append(FriendRequest(
            id: UUID().uuidString, fromID: me, fromName: state.me.name,
            toID: profile.id, toName: profile.name, status: .pending, createdAt: .now
        ))
        save()
    }

    func respond(to request: FriendRequest, accept: Bool) async throws {
        state.incoming.removeAll { $0.id == request.id }
        if accept, !state.friends.contains(where: { $0.id == request.fromID }) {
            state.friends.append(Friend(id: request.fromID, name: request.fromName, since: .now))
        }
        save()
    }

    func removeFriend(_ friend: Friend) async throws {
        state.friends.removeAll { $0.id == friend.id }
        save()
    }

    // MARK: Challenges

    func fetchChallenges() async throws -> [Challenge] {
        simulateFriendActivity()
        return state.challenges.sorted { $0.startDate > $1.startDate }
    }

    func createChallenge(_ draft: ChallengeDraft, friends: [Friend]) async throws -> Challenge {
        let invited = friends.filter { draft.friendIDs.contains($0.id) }
        let challenge = Challenge(
            id: UUID().uuidString,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            type: draft.type,
            creatorID: me,
            startDate: draft.startDate.startOfDay,
            durationDays: draft.durationDays,
            members: [ChallengeMember(id: me, name: state.me.name, state: .joined, checkIns: [])]
                + invited.map { ChallengeMember(id: $0.id, name: $0.name, state: .invited, checkIns: []) },
            createdAt: .now
        )
        state.challenges.append(challenge)
        save()
        return challenge
    }

    func respondToInvite(_ challenge: Challenge, accept: Bool) async throws {
        update(challenge.id) { challenge in
            if let index = challenge.members.firstIndex(where: { $0.id == self.me }) {
                challenge.members[index].state = accept ? .joined : .declined
            }
        }
    }

    func setCheckIn(_ challenge: Challenge, day: Date, done: Bool) async throws {
        let key = DayKey.string(from: day)
        update(challenge.id) { challenge in
            if let index = challenge.members.firstIndex(where: { $0.id == self.me }) {
                if done {
                    challenge.members[index].checkIns.insert(key)
                } else {
                    challenge.members[index].checkIns.remove(key)
                }
            }
        }
    }

    func leaveChallenge(_ challenge: Challenge) async throws {
        state.challenges.removeAll { $0.id == challenge.id }
        save()
    }

    private func update(_ id: String, _ change: (inout Challenge) -> Void) {
        guard let index = state.challenges.firstIndex(where: { $0.id == id }) else { return }
        change(&state.challenges[index])
        save()
    }

    // MARK: Simulation

    /// Makes the demo feel alive: requests get accepted, invites get joined,
    /// and friends check in on the days they "would" have.
    private func simulateFriendActivity() {
        let now = Date.now
        var changed = false

        for request in state.outgoing where now.timeIntervalSince(request.createdAt) > 4 {
            state.outgoing.removeAll { $0.id == request.id }
            if !state.friends.contains(where: { $0.id == request.toID }) {
                state.friends.append(Friend(id: request.toID, name: request.toName, since: now))
            }
            changed = true
        }

        for index in state.challenges.indices {
            let challenge = state.challenges[index]
            for memberIndex in challenge.members.indices where challenge.members[memberIndex].id != me {
                var member = challenge.members[memberIndex]
                if member.state == .invited, challenge.creatorID == me, now.timeIntervalSince(challenge.createdAt) > 3 {
                    member.state = .joined
                }
                if member.state == .joined {
                    for key in challenge.countedDays(today: now) where Self.wouldCheckIn(member.id, key) {
                        member.checkIns.insert(key)
                    }
                }
                if member != challenge.members[memberIndex] {
                    state.challenges[index].members[memberIndex] = member
                    changed = true
                }
            }
        }

        if changed { save() }
    }

    /// Deterministic "did this friend check in that day?" so results are stable.
    private static func wouldCheckIn(_ memberID: String, _ day: String) -> Bool {
        let rates = ["demo-sara": 0.9, "demo-omar": 0.7, "demo-lina": 0.8, "demo-khalid": 0.55, "demo-faisal": 0.65, "demo-noura": 0.75]
        let rate = rates[memberID] ?? 0.7
        let seed = (memberID + day).unicodeScalars.reduce(UInt64(5381)) { ($0 << 5) &+ $0 &+ UInt64($1.value) }
        return Double(seed % 1000) / 1000 < rate
    }

    // MARK: Seed data

    private static func seed() -> State {
        let today = Date.now.startOfDay
        let admin = UserProfile(id: "demo-admin", name: "Admin", email: "admin@ritm.app", phone: "+966500000000", age: 30, createdAt: today)

        let directory = [
            DemoUser(id: "demo-sara", name: "Sara", email: "sara@demo.ritm", phone: "+966500000001"),
            DemoUser(id: "demo-omar", name: "Omar", email: "omar@demo.ritm", phone: "+966500000002"),
            DemoUser(id: "demo-lina", name: "Lina", email: "lina@demo.ritm", phone: "+966500000003"),
            DemoUser(id: "demo-khalid", name: "Khalid", email: "khalid@demo.ritm", phone: "+966500000004"),
            DemoUser(id: "demo-faisal", name: "Faisal", email: "faisal@demo.ritm", phone: "+966500000005"),
            DemoUser(id: "demo-noura", name: "Noura", email: "noura@demo.ritm", phone: "+966500000006"),
        ]
        let friends = directory.prefix(4).map { Friend(id: $0.id, name: $0.name, since: today.addingDays(-40)) }

        func member(_ id: String, _ name: String, _ state: ChallengeMember.State = .joined) -> ChallengeMember {
            ChallengeMember(id: id, name: name, state: state, checkIns: [])
        }

        func myCheckIns(start: Date, days: Int, skipping: Set<Int>) -> Set<String> {
            Set((0..<days).filter { !skipping.contains($0) }.map { DayKey.string(from: start.addingDays($0)) })
        }

        // Active 1 vs 1, day 5 of 7. Today not checked yet.
        let duelStart = today.addingDays(-4)
        var duelMe = member(admin.id, admin.name)
        duelMe.checkIns = myCheckIns(start: duelStart, days: 4, skipping: [2])
        let duel = Challenge(
            id: "demo-duel", title: String(localized: "Walk for 30 min daily"), category: .health, type: .oneVsOne,
            creatorID: admin.id, startDate: duelStart, durationDays: 7,
            members: [duelMe, member("demo-sara", "Sara")], createdAt: duelStart
        )

        // Active group, day 10 of 21.
        let groupStart = today.addingDays(-9)
        var groupMe = member(admin.id, admin.name)
        groupMe.checkIns = myCheckIns(start: groupStart, days: 9, skipping: [3, 6])
        let group = Challenge(
            id: "demo-group", title: String(localized: "Read 10 pages"), category: .learning, type: .group,
            creatorID: "demo-lina", startDate: groupStart, durationDays: 21,
            members: [groupMe, member("demo-lina", "Lina"), member("demo-omar", "Omar"), member("demo-khalid", "Khalid")],
            createdAt: groupStart
        )

        // Finished group challenge, to show the results board.
        let pastStart = today.addingDays(-20)
        var pastMe = member(admin.id, admin.name)
        pastMe.checkIns = myCheckIns(start: pastStart, days: 14, skipping: [5, 11])
        let finished = Challenge(
            id: "demo-finished", title: String(localized: "No takeout spending"), category: .finance, type: .group,
            creatorID: admin.id, startDate: pastStart, durationDays: 14,
            members: [pastMe, member("demo-sara", "Sara"), member("demo-omar", "Omar"), member("demo-lina", "Lina"), member("demo-khalid", "Khalid")],
            createdAt: pastStart
        )

        // An invitation waiting for you.
        let invite = Challenge(
            id: "demo-invite", title: String(localized: "Deep work for 1 hour"), category: .work, type: .oneVsOne,
            creatorID: "demo-omar", startDate: today.addingDays(1), durationDays: 14,
            members: [member("demo-omar", "Omar"), member(admin.id, admin.name, .invited)],
            createdAt: today
        )

        let request = FriendRequest(
            id: "demo-request", fromID: "demo-faisal", fromName: "Faisal", toID: admin.id, toName: admin.name,
            status: .pending, createdAt: today
        )

        return State(
            version: stateVersion,
            me: admin,
            directory: directory,
            friends: Array(friends),
            incoming: [request],
            outgoing: [],
            challenges: [duel, group, finished, invite]
        )
    }
}
