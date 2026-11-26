import SwiftData
import SwiftUI

/// A person's profile: photo, bio, favorite habit and showcase badges.
/// Your own profile adds an Edit button; a friend's adds a Challenge button.
struct ProfileView: View {
    let userID: String

    @Environment(SessionStore.self) private var session
    @Query private var records: [AchievementRecord]
    @State private var isEditing = false
    @State private var isChallenging = false
    @State private var appeared = false

    private var isMe: Bool { userID == session.user?.id }

    private var profile: PublicProfile {
        if let profile = session.profile(for: userID) { return profile }
        if isMe, let mine = session.myProfile { return mine }
        let name = session.friends.first { $0.id == userID }?.name ?? ""
        return PublicProfile(id: userID, name: name)
    }

    private var accentColors: [Color] {
        if let category = profile.favoriteCategory {
            return [category.color, category.color.opacity(0.6), .indigo.opacity(0.7)]
        }
        return [.indigo, .purple, .pink.opacity(0.8)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if !profile.favoriteHabit.isEmpty || profile.favoriteCategory != nil {
                    favoriteHabitCard
                }
                showcaseCard
                statsRow
                if !isMe {
                    PrimaryButton(title: "Challenge", icon: "bolt.fill") { isChallenging = true }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isMe {
                    Button("Edit") { isEditing = true }
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView(profile: profile)
        }
        .sheet(isPresented: $isChallenging) {
            CreateChallengeView(preselectedFriendID: userID)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.05)) { appeared = true }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: accentColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 110)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: profile.favoriteCategory?.icon ?? "sparkles")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(.white.opacity(0.15))
                        .rotationEffect(.degrees(-12))
                        .offset(x: -16, y: 10)
                }

            VStack(spacing: 8) {
                AvatarView(name: profile.name, id: profile.id, size: 112)
                    .overlay(Circle().strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 5))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .padding(.top, -60)

                Text(profile.name)
                    .font(.title2.weight(.bold))

                if profile.bio.isEmpty {
                    if isMe {
                        Button {
                            isEditing = true
                        } label: {
                            Label("Add a bio", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.indigo)
                    }
                } else {
                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var favoriteHabitCard: some View {
        let category = profile.favoriteCategory ?? .personal
        return HStack(spacing: 14) {
            Image(systemName: category.icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(category.color.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Favorite Habit")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(profile.favoriteHabit.isEmpty ? category.title : profile.favoriteHabit)
                    .font(.headline)
            }
            Spacer(minLength: 0)
            Image(systemName: "heart.fill")
                .foregroundStyle(category.color)
        }
        .padding(16)
        .cardStyle(cornerRadius: 20)
    }

    // MARK: Showcase

    private var showcaseCard: some View {
        let badges = profile.showcaseAchievements
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Showcase", systemImage: "rosette")
                    .font(.headline)
                Spacer()
                if isMe {
                    Button {
                        isEditing = true
                    } label: {
                        badges.isEmpty ? Text("Choose") : Text("Change")
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(.indigo)
                }
            }

            if badges.isEmpty {
                HStack(spacing: 12) {
                    ForEach(0..<PublicProfile.showcaseLimit, id: \.self) { _ in
                        Circle()
                            .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                            .frame(width: 64, height: 64)
                            .frame(maxWidth: .infinity)
                    }
                }
                if isMe {
                    Text("Pick up to 3 badges you've earned to show your friends.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No badges showcased yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(badges.enumerated()), id: \.element) { index, achievement in
                        VStack(spacing: 8) {
                            BadgeView(achievement: achievement, size: 72, animated: true)
                                .scaleEffect(appeared ? 1 : 0.3)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15 + Double(index) * 0.12), value: appeared)
                            Text(achievement.title)
                                .font(.caption.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(achievement.tier.title)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle(cornerRadius: 20)
    }

    // MARK: Stats

    private var statsRow: some View {
        let shared = session.challenges.filter { challenge in
            challenge.member(userID)?.state == .joined && challenge.member(session.user?.id ?? "")?.state == .joined
        }
        return HStack(spacing: 12) {
            if isMe {
                stat(value: session.friends.count, title: "Friends", icon: "person.2.fill", color: .blue)
                stat(value: shared.count, title: "Challenges", icon: "flag.2.crossed.fill", color: .orange)
                stat(value: records.filter { !$0.isMilestone }.count, title: "Badges", icon: "rosette", color: .purple)
            } else {
                stat(value: shared.count, title: "Challenges together", icon: "flag.2.crossed.fill", color: .orange)
                stat(value: profile.showcase.count, title: "Showcased", icon: "rosette", color: .purple)
            }
        }
    }

    private func stat(value: Int, title: LocalizedStringKey, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value, format: .number)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle(cornerRadius: 18)
    }
}
