import SwiftUI

/// Your profile card, friend requests and friends, with quick 1 vs 1 challenges.
struct FriendsView: View {
    @Environment(SessionStore.self) private var session
    @State private var isAdding = false
    @State private var challengeFriend: Friend?
    @State private var friendToRemove: Friend?

    var body: some View {
        NavigationStack {
            List {
                if let user = session.user {
                    Section {
                        ZStack {
                            // Hidden link so the whole card opens your profile without a list chevron.
                            NavigationLink { ProfileView(userID: user.id) } label: { EmptyView() }
                                .opacity(0)
                            profileCard(user)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if !session.incomingRequests.isEmpty {
                    Section {
                        ForEach(session.incomingRequests) { request in
                            IncomingRequestRow(request: request)
                        }
                    } header: {
                        Text("Friend Requests")
                    }
                }

                Section {
                    if session.friends.isEmpty {
                        emptyFriends
                    } else {
                        ForEach(session.friends) { friend in
                            NavigationLink {
                                ProfileView(userID: friend.id)
                            } label: {
                                friendRow(friend)
                            }
                            .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        friendToRemove = friend
                                    } label: {
                                        Label("Remove", systemImage: "person.fill.xmark")
                                    }
                                }
                        }
                    }
                } header: {
                    Text("Friends (\(session.friends.count))")
                }

                if !session.outgoingRequests.isEmpty {
                    Section {
                        ForEach(session.outgoingRequests) { request in
                            HStack(spacing: 12) {
                                AvatarView(name: request.toName, id: request.toID, size: 40)
                                Text(request.toName)
                                    .font(.body.weight(.medium))
                                Spacer()
                                Label("Pending", systemImage: "clock.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Sent Requests")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                    }
                    .accessibilityLabel(Text("Add Friend"))
                }
            }
            .refreshable { await session.refresh() }
            .sheet(isPresented: $isAdding) {
                AddFriendSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $challengeFriend) { friend in
                CreateChallengeView(preselectedFriendID: friend.id)
            }
            .confirmationDialog(
                Text("Remove \(friendToRemove?.name ?? "") from your friends?"),
                isPresented: Binding(get: { friendToRemove != nil }, set: { if !$0 { friendToRemove = nil } }),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let friend = friendToRemove {
                        Task { await session.perform { try await $0.removeFriend(friend) } }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func profileCard(_ user: UserProfile) -> some View {
        HStack(spacing: 16) {
            AvatarView(name: user.name, id: user.id, size: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.title3.weight(.bold))
                Text(session.myProfile?.bio.isEmpty == false ? session.myProfile?.bio ?? "" : user.email)
                    .font(.subheadline)
                    .opacity(0.85)
                    .lineLimit(2)
                Label("View & edit profile", systemImage: "pencil.circle.fill")
                    .font(.caption.weight(.semibold))
                    .opacity(0.85)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward")
                .font(.subheadline.weight(.bold))
                .opacity(0.7)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: friend.name, id: friend.id, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.body.weight(.semibold))
                if let bio = session.profile(for: friend.id)?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Friends since \(friend.since.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                challengeFriend = friend
            } label: {
                Label("Challenge", systemImage: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing), in: Capsule())
            }
            // Borderless keeps this tap separate from the row's link to the profile.
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    private var emptyFriends: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient.brand)
            Text("No friends yet")
                .font(.headline)
            Text("Add friends by their email or phone number, then challenge them!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                isAdding = true
            } label: {
                Label("Add a Friend", systemImage: "person.badge.plus")
                    .font(.subheadline.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct IncomingRequestRow: View {
    @Environment(SessionStore.self) private var session
    let request: FriendRequest
    @State private var isWorking = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: request.fromName, id: request.fromID, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromName)
                    .font(.body.weight(.semibold))
                Text("wants to be your friend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                respond(accept: false)
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(Text("Decline"))

            Button {
                respond(accept: true)
            } label: {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.green.gradient, in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(Text("Accept"))
        }
        .disabled(isWorking)
        .opacity(isWorking ? 0.5 : 1)
    }

    private func respond(accept: Bool) {
        isWorking = true
        Task {
            await session.perform { try await $0.respond(to: request, accept: accept) }
            isWorking = false
        }
    }
}

/// Find a friend by exact email or phone and send a request.
struct AddFriendSheet: View {
    enum Field: Hashable { case query }
    enum SearchState: Equatable {
        case idle, searching, notFound, found(PublicProfile), sent(PublicProfile), failed(String)
    }

    @Environment(SessionStore.self) private var session
    @FocusState private var focus: Field?
    @State private var query = ""
    @State private var state: SearchState = .idle

    private var queryIsValid: Bool {
        FormValidation.email(query).isValid || FormValidation.phone(query).isValid
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(LinearGradient.brand)
                    .symbolEffect(.bounce, value: state)
                Text("Add a Friend")
                    .font(.title2.weight(.bold))
                Text("Search by their email or phone number.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            HStack(spacing: 10) {
                AuthTextField(
                    icon: "magnifyingglass", placeholder: "Email or phone", text: $query,
                    keyboard: .emailAddress, submitLabel: .search,
                    focus: $focus, field: .query, onSubmit: search
                )
                Button(action: search) {
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(LinearGradient.brand).opacity(queryIsValid ? 1 : 0.4))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(!queryIsValid || state == .searching)
                .accessibilityLabel(Text("Search"))
            }

            resultView
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state)

            if session.isDemo {
                Text("Demo tip: try noura@demo.ritm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            ShareLink(item: String(localized: "Join me on Ritm and let's build our daily rhythm together! 💪")) {
                Label("Invite friends to Ritm", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(20)
        .onAppear { focus = .query }
        .onChange(of: query) { _, _ in
            if case .searching = state { return }
            state = .idle
        }
        .sensoryFeedback(trigger: state) { _, new in
            switch new {
            case .found: .impact(weight: .light)
            case .sent: .success
            case .notFound, .failed: .warning
            default: nil
            }
        }
    }

    @ViewBuilder
    private var resultView: some View {
        switch state {
        case .idle:
            EmptyView()
        case .searching:
            ProgressView()
                .padding()
        case .notFound:
            Label("No Ritm user found with that email or phone.", systemImage: "person.fill.questionmark")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .failed(let message):
            ErrorBanner(message: message)
        case .found(let profile), .sent(let profile):
            let isSent = state == .sent(profile)
            HStack(spacing: 14) {
                AvatarView(name: profile.name, id: profile.id, size: 52)
                Text(profile.name)
                    .font(.headline)
                Spacer()
                Button {
                    send(to: profile)
                } label: {
                    Label {
                        isSent ? Text("Sent") : Text("Add")
                    } icon: {
                        Image(systemName: isSent ? "checkmark" : "person.badge.plus")
                    }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(isSent ? AnyShapeStyle(Color.green.gradient) : AnyShapeStyle(LinearGradient.brand)))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isSent)
            }
            .padding(16)
            .cardStyle(cornerRadius: 20)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }

    private func search() {
        guard queryIsValid else { return }
        focus = nil
        state = .searching
        Task {
            do {
                if let profile = try await session.findUser(emailOrPhone: query) {
                    state = .found(profile)
                } else {
                    state = .notFound
                }
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func send(to profile: PublicProfile) {
        Task {
            if await session.perform({ try await $0.sendFriendRequest(to: profile) }) {
                state = .sent(profile)
            }
        }
    }
}
