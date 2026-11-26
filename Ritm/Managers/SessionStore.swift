import Foundation
import Observation

/// Who's logged in, plus the cached friends and challenges for the social tabs.
@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case loading
        case signedOut
        case signedIn(UserProfile)
    }

    private(set) var phase: Phase = .loading
    private(set) var friends: [Friend] = []
    private(set) var incomingRequests: [FriendRequest] = []
    private(set) var outgoingRequests: [FriendRequest] = []
    private(set) var challenges: [Challenge] = []
    private(set) var isRefreshing = false
    var errorMessage: String?
    /// Set right after login/sign-up to show a welcome banner.
    var welcomeName: String?

    @ObservationIgnored private var backend: SocialBackend?
    @ObservationIgnored private let modeKey = "sessionMode"

    var user: UserProfile? {
        if case .signedIn(let user) = phase { return user }
        return nil
    }

    var isDemo: Bool { backend?.isDemo ?? false }

    /// Whether real online accounts are available (Firebase is configured).
    var isOnlineAvailable: Bool { FirebaseSetup.isReady }

    // MARK: Lifecycle

    func restore() async {
        guard phase == .loading else { return }
        let mode = UserDefaults.standard.string(forKey: modeKey)
        #if DEBUG
        if mode == "demo" {
            let demo = DemoBackend()
            backend = demo
            if let profile = await demo.restoreSession() {
                phase = .signedIn(profile)
                await refresh()
                return
            }
        }
        #endif
        if mode == "online", let online = makeOnlineBackend(), let profile = await online.restoreSession() {
            backend = online
            phase = .signedIn(profile)
            await refresh()
            return
        }
        phase = .signedOut
    }

    func signIn(email: String, password: String) async throws {
        guard let online = makeOnlineBackend() else { throw BackendError.notConfigured }
        let profile = try await online.signIn(email: email, password: password)
        finishLogin(backend: online, profile: profile, mode: "online")
        await refresh()
    }

    func signUp(_ data: SignUpData) async throws {
        guard let online = makeOnlineBackend() else { throw BackendError.notConfigured }
        let profile = try await online.signUp(data)
        finishLogin(backend: online, profile: profile, mode: "online")
        await refresh()
    }

    func sendPasswordReset(email: String) async throws {
        guard let online = makeOnlineBackend() else { throw BackendError.notConfigured }
        try await online.sendPasswordReset(email: email)
    }

    #if DEBUG
    /// Developer-only: log in as "admin" with sample data. Not compiled into release builds.
    func signInAsDemoAdmin() async {
        let demo = DemoBackend()
        guard let profile = try? await demo.signIn(email: "admin", password: "") else { return }
        finishLogin(backend: demo, profile: profile, mode: "demo")
        await refresh()
    }
    #endif

    func signOut() {
        try? backend?.signOut()
        reset()
    }

    func deleteAccount() async throws {
        try await backend?.deleteAccount()
        try? backend?.signOut()
        reset()
    }

    private func finishLogin(backend: SocialBackend, profile: UserProfile, mode: String) {
        self.backend = backend
        UserDefaults.standard.set(mode, forKey: modeKey)
        welcomeName = profile.name
        phase = .signedIn(profile)
    }

    private func reset() {
        UserDefaults.standard.removeObject(forKey: modeKey)
        backend = nil
        friends = []
        incomingRequests = []
        outgoingRequests = []
        challenges = []
        phase = .signedOut
    }

    private func makeOnlineBackend() -> SocialBackend? {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseCore)
        return FirebaseSetup.isReady ? FirebaseBackend() : nil
        #else
        return nil
        #endif
    }

    // MARK: Data

    func refresh() async {
        guard let backend, user != nil else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let friends = try await backend.fetchFriends()
            let requests = try await backend.fetchFriendRequests()
            let challenges = try await backend.fetchChallenges()
            self.friends = friends
            incomingRequests = requests.incoming
            outgoingRequests = requests.outgoing
            self.challenges = challenges
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Runs an action, then refreshes. Errors are shown in an alert.
    @discardableResult
    func perform(_ action: (SocialBackend) async throws -> Void) async -> Bool {
        guard let backend else { return false }
        do {
            try await action(backend)
            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func findUser(emailOrPhone: String) async throws -> PublicProfile? {
        guard let backend else { throw BackendError.notSignedIn }
        return try await backend.findUser(emailOrPhone: emailOrPhone)
    }

    func createChallenge(_ draft: ChallengeDraft) async -> Challenge? {
        guard let backend else { return nil }
        do {
            let challenge = try await backend.createChallenge(draft, friends: friends)
            await refresh()
            return challenge
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Updates the local copy immediately so the check-in feels instant, then syncs.
    func setCheckIn(_ challenge: Challenge, done: Bool) async {
        guard let me = user?.id, let index = challenges.firstIndex(where: { $0.id == challenge.id }),
              let memberIndex = challenges[index].members.firstIndex(where: { $0.id == me })
        else { return }
        let key = DayKey.string(from: .now)
        if done {
            challenges[index].members[memberIndex].checkIns.insert(key)
        } else {
            challenges[index].members[memberIndex].checkIns.remove(key)
        }
        await perform { try await $0.setCheckIn(challenge, day: .now, done: done) }
    }

    func challenge(id: String) -> Challenge? {
        challenges.first { $0.id == id }
    }
}
