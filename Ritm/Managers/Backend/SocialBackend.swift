import Foundation

/// Everything the app needs from an online service for accounts, friends and challenges.
/// `FirebaseBackend` is the real implementation; `DemoBackend` powers the developer-only
/// admin login with sample friends so every screen can be tried without a server.
@MainActor
protocol SocialBackend: AnyObject {
    var isDemo: Bool { get }

    // Account
    func restoreSession() async -> UserProfile?
    func signUp(_ data: SignUpData) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile
    func sendPasswordReset(email: String) async throws
    func signOut() throws
    func deleteAccount() async throws

    // Profiles
    func fetchPublicProfiles(ids: [String]) async throws -> [PublicProfile]
    func updateMyProfile(_ update: ProfileUpdate) async throws

    // Friends
    func findUser(emailOrPhone: String) async throws -> PublicProfile?
    func fetchFriends() async throws -> [Friend]
    func fetchFriendRequests() async throws -> (incoming: [FriendRequest], outgoing: [FriendRequest])
    func sendFriendRequest(to profile: PublicProfile) async throws
    func respond(to request: FriendRequest, accept: Bool) async throws
    func removeFriend(_ friend: Friend) async throws

    // Challenges
    func fetchChallenges() async throws -> [Challenge]
    func createChallenge(_ draft: ChallengeDraft, friends: [Friend]) async throws -> Challenge
    func respondToInvite(_ challenge: Challenge, accept: Bool) async throws
    func setCheckIn(_ challenge: Challenge, day: Date, done: Bool) async throws
    func leaveChallenge(_ challenge: Challenge) async throws
}

/// User-facing errors with friendly, localized messages.
enum BackendError: LocalizedError {
    case notConfigured
    case notSignedIn
    case emailInUse
    case invalidEmail
    case weakPassword
    case wrongCredentials
    case network
    case tooManyAttempts
    case requiresRecentLogin
    case userNotFound
    case cannotAddYourself
    case alreadyFriends
    case requestAlreadySent
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            String(localized: "Online accounts aren't set up yet. Add the Firebase configuration file (see the README), or use the developer admin login.")
        case .notSignedIn: String(localized: "Please log in again.")
        case .emailInUse: String(localized: "An account with this email already exists. Try logging in instead.")
        case .invalidEmail: String(localized: "That email doesn't look right.")
        case .weakPassword: String(localized: "Please choose a stronger password.")
        case .wrongCredentials: String(localized: "The email or password is incorrect.")
        case .network: String(localized: "No internet connection. Please try again.")
        case .tooManyAttempts: String(localized: "Too many attempts. Please wait a moment and try again.")
        case .requiresRecentLogin: String(localized: "For your security, please log out and log in again, then retry.")
        case .userNotFound: String(localized: "No Ritm user found with that email or phone.")
        case .cannotAddYourself: String(localized: "That's you! Search for a friend's email or phone.")
        case .alreadyFriends: String(localized: "You're already friends.")
        case .requestAlreadySent: String(localized: "You already sent a request to this person.")
        case .unknown(let message): message
        }
    }
}
