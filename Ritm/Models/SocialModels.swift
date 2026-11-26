import CryptoKit
import SwiftUI

// MARK: - People

/// The signed-in user's private account details (only visible to them).
struct UserProfile: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var email: String
    var phone: String
    var age: Int
    var createdAt: Date
}

/// What other users can see: a name to show and hashed contact details for lookup.
struct PublicProfile: Codable, Hashable, Identifiable {
    let id: String
    var name: String
}

struct Friend: Codable, Hashable, Identifiable {
    let id: String
    var name: String
    var since: Date
}

struct FriendRequest: Codable, Hashable, Identifiable {
    enum Status: String, Codable { case pending, accepted, declined }

    let id: String
    var fromID: String
    var fromName: String
    var toID: String
    var toName: String
    var status: Status
    var createdAt: Date
}

// MARK: - Challenges

enum ChallengeType: String, Codable, CaseIterable, Identifiable {
    case oneVsOne, group

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneVsOne: String(localized: "1 vs 1")
        case .group: String(localized: "Group")
        }
    }

    var subtitle: String {
        switch self {
        case .oneVsOne: String(localized: "Go head to head with one friend")
        case .group: String(localized: "Compete with a group of friends")
        }
    }

    var icon: String {
        switch self {
        case .oneVsOne: "figure.fencing"
        case .group: "person.3.fill"
        }
    }
}

struct ChallengeMember: Codable, Hashable, Identifiable {
    enum State: String, Codable { case invited, joined, declined }

    let id: String
    var name: String
    var state: State
    /// Day keys ("yyyy-MM-dd") on which the member checked in.
    var checkIns: Set<String>
}

struct Challenge: Codable, Hashable, Identifiable {
    enum Phase { case upcoming, active, finished }

    let id: String
    var title: String
    var category: GoalCategory
    var type: ChallengeType
    var creatorID: String
    /// Start of the first day.
    var startDate: Date
    var durationDays: Int
    var members: [ChallengeMember]
    var createdAt: Date

    var endDate: Date { startDate.addingDays(durationDays - 1) }

    func phase(today: Date = .now) -> Phase {
        let day = today.startOfDay
        if day < startDate.startOfDay { return .upcoming }
        if day > endDate { return .finished }
        return .active
    }

    /// 1-based day number of the challenge (clamped to its length).
    func dayNumber(today: Date = .now) -> Int {
        min(durationDays, max(0, Calendar.current.numberOfDays(from: startDate, to: today) + 1))
    }

    var joinedMembers: [ChallengeMember] { members.filter { $0.state == .joined } }

    func member(_ id: String) -> ChallengeMember? { members.first { $0.id == id } }

    /// Days that count: from the start until today or the end, whichever is first.
    func countedDays(today: Date = .now) -> [String] {
        let last = min(endDate, today.startOfDay)
        let count = Calendar.current.numberOfDays(from: startDate, to: last) + 1
        guard count > 0 else { return [] }
        return (0..<count).map { DayKey.string(from: startDate.addingDays($0)) }
    }

    func leaderboard(today: Date = .now) -> [LeaderboardEntry] {
        let days = countedDays(today: today)
        let window = Set(days)
        let possible = max(1, days.count)

        let raw = joinedMembers.map { member -> (ChallengeMember, Int, Int) in
            let done = member.checkIns.intersection(window)
            var best = 0
            var run = 0
            for day in days {
                run = done.contains(day) ? run + 1 : 0
                best = max(best, run)
            }
            return (member, done.count, best)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            if lhs.2 != rhs.2 { return lhs.2 > rhs.2 }
            return lhs.0.name.localizedCompare(rhs.0.name) == .orderedAscending
        }

        var entries: [LeaderboardEntry] = []
        for (index, item) in raw.enumerated() {
            let rank: Int
            if let previous = entries.last, previous.completed == item.1, previous.bestStreak == item.2 {
                rank = previous.rank
            } else {
                rank = index + 1
            }
            let rate = Double(item.1) / Double(possible)
            entries.append(LeaderboardEntry(member: item.0, completed: item.1, bestStreak: item.2, rate: rate, rank: rank))
        }
        return entries
    }

    /// Average completion of everyone who joined.
    func groupRate(today: Date = .now) -> Double {
        let board = leaderboard(today: today)
        guard !board.isEmpty else { return 0 }
        return board.reduce(0) { $0 + $1.rate } / Double(board.count)
    }

    /// Everyone sharing first place once the challenge is over.
    func winners(today: Date = .now) -> [LeaderboardEntry] {
        let board = leaderboard(today: today)
        guard let top = board.first, top.completed > 0 else { return [] }
        return board.filter { $0.rank == 1 }
    }
}

struct LeaderboardEntry: Identifiable, Hashable {
    var id: String { member.id }
    let member: ChallengeMember
    let completed: Int
    let bestStreak: Int
    let rate: Double
    let rank: Int

    var grade: Grade { Grade(rate: rate) }
}

/// Letter grade from a completion rate.
enum Grade: String {
    case aPlus = "A+", a = "A", b = "B", c = "C", d = "D", f = "F"

    init(rate: Double) {
        switch rate {
        case 0.95...: self = .aPlus
        case 0.85..<0.95: self = .a
        case 0.70..<0.85: self = .b
        case 0.55..<0.70: self = .c
        case 0.40..<0.55: self = .d
        default: self = .f
        }
    }

    var color: Color {
        switch self {
        case .aPlus, .a: .green
        case .b: .mint
        case .c: .yellow
        case .d: .orange
        case .f: .red
        }
    }

    var praise: String {
        switch self {
        case .aPlus: String(localized: "Outstanding teamwork!")
        case .a: String(localized: "Excellent effort!")
        case .b: String(localized: "Great job, team!")
        case .c: String(localized: "Good effort. Keep pushing!")
        case .d: String(localized: "A start. Next time, stronger!")
        case .f: String(localized: "Every journey starts somewhere.")
        }
    }
}

/// What the user fills in when creating a challenge.
struct ChallengeDraft {
    var title = ""
    var category: GoalCategory = .health
    var type: ChallengeType = .oneVsOne
    var durationDays = 7
    var startDate = Date.now.startOfDay
    var friendIDs: Set<String> = []
}

struct SignUpData {
    var name = ""
    var age = ""
    var email = ""
    var phone = ""
    var password = ""
    var confirmPassword = ""
}

// MARK: - Helpers

/// Stable "yyyy-MM-dd" day identifiers shared between friends' devices.
enum DayKey {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter.timeZone = .current
        return formatter.date(from: string)
    }
}

enum ContactHash {
    /// SHA-256 of a normalized email, so users can be found by exact email
    /// without anyone being able to browse other people's addresses.
    static func email(_ email: String) -> String {
        sha256(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }

    /// SHA-256 of the phone number's digits.
    static func phone(_ phone: String) -> String {
        sha256(phone.filter(\.isNumber))
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
