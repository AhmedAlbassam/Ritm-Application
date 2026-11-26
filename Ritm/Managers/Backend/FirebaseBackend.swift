import Foundation

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseCore)
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

enum FirebaseSetup {
    /// True when GoogleService-Info.plist was added to the app (see README).
    static var hasConfigFile: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    static func configureIfPossible() {
        guard hasConfigFile, FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    static var isReady: Bool { FirebaseApp.app() != nil }
}

/// Firestore layout:
/// - users/{uid}                 private profile (name, email, phone, age) — readable by the owner only
/// - publicProfiles/{uid}        name + hashed email/phone, used to find friends
/// - friendRequests/{id}         fromID, toID, names, status
/// - friendships/{uidA_uidB}     members [uidA, uidB], names {uid: name}
/// - challenges/{id}             details, memberIds, members {uid: {name, state}}, progress {uid: [dayKeys]}
@MainActor
final class FirebaseBackend: SocialBackend {
    let isDemo = false

    private var db: Firestore { Firestore.firestore() }

    private var uid: String {
        get throws {
            guard let uid = Auth.auth().currentUser?.uid else { throw BackendError.notSignedIn }
            return uid
        }
    }

    private var myName = ""

    // MARK: Account

    func restoreSession() async -> UserProfile? {
        guard let user = Auth.auth().currentUser else { return nil }
        return try? await loadProfile(uid: user.uid)
    }

    func signUp(_ data: SignUpData) async throws -> UserProfile {
        do {
            let email = data.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let result = try await Auth.auth().createUser(withEmail: email, password: data.password)
            let name = data.name.trimmingCharacters(in: .whitespacesAndNewlines)

            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try? await change.commitChanges()

            let profile = UserProfile(
                id: result.user.uid,
                name: name,
                email: email,
                phone: data.phone.trimmingCharacters(in: .whitespacesAndNewlines),
                age: Int(data.age) ?? 0,
                createdAt: .now
            )

            let batch = db.batch()
            batch.setData([
                "name": profile.name,
                "email": profile.email,
                "phone": profile.phone,
                "age": profile.age,
                "createdAt": Timestamp(date: profile.createdAt),
            ], forDocument: db.collection("users").document(profile.id))
            batch.setData([
                "name": profile.name,
                "emailHash": ContactHash.email(profile.email),
                "phoneHash": ContactHash.phone(profile.phone),
            ], forDocument: db.collection("publicProfiles").document(profile.id))
            try await batch.commit()

            myName = profile.name
            return profile
        } catch {
            throw Self.map(error)
        }
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().signIn(
                withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password
            )
            return try await loadProfile(uid: result.user.uid)
        } catch {
            throw Self.map(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            throw Self.map(error)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        myName = ""
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { throw BackendError.notSignedIn }
        do {
            let uid = user.uid
            let batch = db.batch()
            batch.deleteDocument(db.collection("users").document(uid))
            batch.deleteDocument(db.collection("publicProfiles").document(uid))
            for doc in try await db.collection("friendships").whereField("members", arrayContains: uid).getDocuments().documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
            try await user.delete()
        } catch {
            throw Self.map(error)
        }
    }

    private func loadProfile(uid: String) async throws -> UserProfile {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        let data = snapshot.data() ?? [:]
        let fallbackName = Auth.auth().currentUser?.displayName ?? ""
        let profile = UserProfile(
            id: uid,
            name: data["name"] as? String ?? fallbackName,
            email: data["email"] as? String ?? Auth.auth().currentUser?.email ?? "",
            phone: data["phone"] as? String ?? "",
            age: data["age"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        )
        myName = profile.name
        return profile
    }

    // MARK: Friends

    func findUser(emailOrPhone: String) async throws -> PublicProfile? {
        let me = try uid
        let query = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEmail = query.contains("@")
        let field = isEmail ? "emailHash" : "phoneHash"
        let hash = isEmail ? ContactHash.email(query) : ContactHash.phone(query)

        do {
            let docs = try await db.collection("publicProfiles").whereField(field, isEqualTo: hash).limit(to: 1).getDocuments().documents
            guard let doc = docs.first else { return nil }
            if doc.documentID == me { throw BackendError.cannotAddYourself }
            return PublicProfile(id: doc.documentID, name: doc.data()["name"] as? String ?? "")
        } catch let error as BackendError {
            throw error
        } catch {
            throw Self.map(error)
        }
    }

    func fetchFriends() async throws -> [Friend] {
        let me = try uid
        let docs = try await db.collection("friendships").whereField("members", arrayContains: me).getDocuments().documents
        return docs.compactMap { doc in
            let data = doc.data()
            guard let members = data["members"] as? [String],
                  let other = members.first(where: { $0 != me }) else { return nil }
            let names = data["names"] as? [String: String] ?? [:]
            return Friend(id: other, name: names[other] ?? "", since: (data["since"] as? Timestamp)?.dateValue() ?? .now)
        }
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func fetchFriendRequests() async throws -> (incoming: [FriendRequest], outgoing: [FriendRequest]) {
        let me = try uid
        let requests = db.collection("friendRequests")
        let incomingDocs = try await requests.whereField("toID", isEqualTo: me).whereField("status", isEqualTo: "pending").getDocuments()
        let outgoingDocs = try await requests.whereField("fromID", isEqualTo: me).whereField("status", isEqualTo: "pending").getDocuments()
        let incoming = incomingDocs.documents.compactMap(Self.request)
        let outgoing = outgoingDocs.documents.compactMap(Self.request)
        return (incoming, outgoing)
    }

    func sendFriendRequest(to profile: PublicProfile) async throws {
        let me = try uid
        if profile.id == me { throw BackendError.cannotAddYourself }

        let friendshipID = Self.friendshipID(me, profile.id)
        if try await db.collection("friendships").document(friendshipID).getDocument().exists {
            throw BackendError.alreadyFriends
        }
        let existing = try await db.collection("friendRequests")
            .whereField("fromID", isEqualTo: me)
            .whereField("toID", isEqualTo: profile.id)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        if !existing.documents.isEmpty { throw BackendError.requestAlreadySent }

        try await db.collection("friendRequests").document().setData([
            "fromID": me,
            "fromName": myName,
            "toID": profile.id,
            "toName": profile.name,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    func respond(to request: FriendRequest, accept: Bool) async throws {
        let batch = db.batch()
        batch.updateData(["status": accept ? "accepted" : "declined"], forDocument: db.collection("friendRequests").document(request.id))
        if accept {
            batch.setData([
                "members": [request.fromID, request.toID],
                "names": [request.fromID: request.fromName, request.toID: request.toName],
                "since": FieldValue.serverTimestamp(),
            ], forDocument: db.collection("friendships").document(Self.friendshipID(request.fromID, request.toID)))
        }
        try await batch.commit()
    }

    func removeFriend(_ friend: Friend) async throws {
        let me = try uid
        try await db.collection("friendships").document(Self.friendshipID(me, friend.id)).delete()
    }

    // MARK: Challenges

    func fetchChallenges() async throws -> [Challenge] {
        let me = try uid
        let docs = try await db.collection("challenges").whereField("memberIds", arrayContains: me).getDocuments().documents
        return docs.compactMap(Self.challenge).sorted { $0.startDate > $1.startDate }
    }

    func createChallenge(_ draft: ChallengeDraft, friends: [Friend]) async throws -> Challenge {
        let me = try uid
        let invited = friends.filter { draft.friendIDs.contains($0.id) }
        let members = [ChallengeMember(id: me, name: myName, state: .joined, checkIns: [])]
            + invited.map { ChallengeMember(id: $0.id, name: $0.name, state: .invited, checkIns: []) }

        let ref = db.collection("challenges").document()
        let challenge = Challenge(
            id: ref.documentID,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            type: draft.type,
            creatorID: me,
            startDate: draft.startDate.startOfDay,
            durationDays: draft.durationDays,
            members: members,
            createdAt: .now
        )

        var memberMap: [String: Any] = [:]
        var progress: [String: Any] = [:]
        for member in members {
            memberMap[member.id] = ["name": member.name, "state": member.state.rawValue]
            progress[member.id] = [String]()
        }

        try await ref.setData([
            "title": challenge.title,
            "category": challenge.category.rawValue,
            "type": challenge.type.rawValue,
            "creatorID": me,
            "startDay": DayKey.string(from: challenge.startDate),
            "durationDays": challenge.durationDays,
            "memberIds": members.map(\.id),
            "members": memberMap,
            "progress": progress,
            "createdAt": FieldValue.serverTimestamp(),
        ])
        return challenge
    }

    func respondToInvite(_ challenge: Challenge, accept: Bool) async throws {
        let me = try uid
        try await db.collection("challenges").document(challenge.id).updateData([
            "members.\(me).state": accept ? ChallengeMember.State.joined.rawValue : ChallengeMember.State.declined.rawValue,
        ])
    }

    func setCheckIn(_ challenge: Challenge, day: Date, done: Bool) async throws {
        let me = try uid
        let key = DayKey.string(from: day)
        try await db.collection("challenges").document(challenge.id).updateData([
            "progress.\(me)": done ? FieldValue.arrayUnion([key]) : FieldValue.arrayRemove([key]),
        ])
    }

    func leaveChallenge(_ challenge: Challenge) async throws {
        let me = try uid
        let ref = db.collection("challenges").document(challenge.id)
        if challenge.creatorID == me {
            try await ref.delete()
        } else {
            try await ref.updateData([
                "memberIds": FieldValue.arrayRemove([me]),
                "members.\(me)": FieldValue.delete(),
                "progress.\(me)": FieldValue.delete(),
            ])
        }
    }

    // MARK: Parsing

    private static func friendshipID(_ a: String, _ b: String) -> String {
        [a, b].sorted().joined(separator: "_")
    }

    private static func request(_ doc: QueryDocumentSnapshot) -> FriendRequest? {
        let data = doc.data()
        guard let fromID = data["fromID"] as? String, let toID = data["toID"] as? String else { return nil }
        return FriendRequest(
            id: doc.documentID,
            fromID: fromID,
            fromName: data["fromName"] as? String ?? "",
            toID: toID,
            toName: data["toName"] as? String ?? "",
            status: FriendRequest.Status(rawValue: data["status"] as? String ?? "") ?? .pending,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }

    private static func challenge(_ doc: QueryDocumentSnapshot) -> Challenge? {
        let data = doc.data()
        guard let title = data["title"] as? String,
              let startDay = data["startDay"] as? String,
              let startDate = DayKey.date(from: startDay),
              let duration = data["durationDays"] as? Int
        else { return nil }

        let memberMap = data["members"] as? [String: [String: Any]] ?? [:]
        let progress = data["progress"] as? [String: [String]] ?? [:]
        let members = memberMap.map { id, info in
            ChallengeMember(
                id: id,
                name: info["name"] as? String ?? "",
                state: ChallengeMember.State(rawValue: info["state"] as? String ?? "") ?? .invited,
                checkIns: Set(progress[id] ?? [])
            )
        }
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }

        return Challenge(
            id: doc.documentID,
            title: title,
            category: GoalCategory(rawValue: data["category"] as? String ?? "") ?? .personal,
            type: ChallengeType(rawValue: data["type"] as? String ?? "") ?? .group,
            creatorID: data["creatorID"] as? String ?? "",
            startDate: startDate.startOfDay,
            durationDays: duration,
            members: members,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
        )
    }

    /// Turns Firebase errors into friendly messages.
    private static func map(_ error: Error) -> Error {
        if error is BackendError { return error }
        let nsError = error as NSError
        guard nsError.domain == "FIRAuthErrorDomain" else {
            // 14 = UNAVAILABLE (offline / server unreachable)
            if nsError.domain == "FIRFirestoreErrorDomain", nsError.code == 14 {
                return BackendError.network
            }
            return BackendError.unknown(nsError.localizedDescription)
        }
        switch nsError.code {
        case 17007: return BackendError.emailInUse
        case 17008: return BackendError.invalidEmail
        case 17026: return BackendError.weakPassword
        case 17009, 17011, 17004: return BackendError.wrongCredentials
        case 17020: return BackendError.network
        case 17010: return BackendError.tooManyAttempts
        case 17014: return BackendError.requiresRecentLogin
        default: return BackendError.unknown(nsError.localizedDescription)
        }
    }
}

#else

enum FirebaseSetup {
    static var hasConfigFile: Bool { false }
    static func configureIfPossible() {}
    static var isReady: Bool { false }
}

#endif
