import SwiftUI

/// Pick 1 vs 1 or group, the habit, duration, start day and friends.
struct CreateChallengeView: View {
    enum Field: Hashable { case title }

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    @State private var draft: ChallengeDraft
    @State private var startsTomorrow = false
    @State private var isCreating = false
    @State private var created = false

    private static let durations = [7, 14, 21, 30]

    init(preselectedFriendID: String? = nil) {
        var draft = ChallengeDraft()
        if let preselectedFriendID {
            draft.friendIDs = [preselectedFriendID]
            draft.type = .oneVsOne
        }
        _draft = State(initialValue: draft)
    }

    private var friendsValid: Bool {
        switch draft.type {
        case .oneVsOne: draft.friendIDs.count == 1
        case .group: draft.friendIDs.count >= 2
        }
    }

    private var isValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && friendsValid
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    typeSection
                    habitSection
                    durationSection
                    friendsSection
                }
                .padding(16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Start Challenge", icon: "flag.checkered", isLoading: isCreating, isEnabled: isValid, action: create)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.bar)
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sensoryFeedback(.selection, trigger: draft.type)
            .sensoryFeedback(.selection, trigger: draft.category)
            .sensoryFeedback(.success, trigger: created)
        }
    }

    // MARK: Sections

    private func sectionTitle(_ title: LocalizedStringKey, step: Int) -> some View {
        HStack(spacing: 8) {
            Text(step, format: .number)
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(LinearGradient.brand, in: Circle())
            Text(title)
                .font(.headline)
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Challenge type", step: 1)
            HStack(spacing: 12) {
                ForEach(ChallengeType.allCases) { type in
                    let selected = draft.type == type
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            draft.type = type
                            if type == .oneVsOne, draft.friendIDs.count > 1 {
                                draft.friendIDs = Set(draft.friendIDs.prefix(1))
                            }
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.system(size: 30, weight: .semibold))
                                .symbolEffect(.bounce, value: selected)
                            Text(type.title)
                                .font(.headline)
                            Text(type.subtitle)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .opacity(0.85)
                        }
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(selected ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                        )
                        .scaleEffect(selected ? 1 : 0.97)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.95))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var habitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Habit", step: 2)

            TextField("e.g., \(GoalFormModel.titlePlaceholder)", text: $draft.title)
                .font(.body.weight(.medium))
                .focused($focus, equals: .title)
                .submitLabel(.done)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(GoalTemplate.suggestions) { template in
                        Button {
                            withAnimation(.snappy) {
                                draft.title = template.title
                                draft.category = template.category
                            }
                        } label: {
                            Label(template.title, systemImage: template.category.icon)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(template.category.color.opacity(0.14), in: Capsule())
                                .foregroundStyle(template.category.color)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.95))
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(GoalCategory.allCases) { category in
                    CategoryTile(category: category, isSelected: draft.category == category) {
                        withAnimation(.snappy) { draft.category = category }
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Duration & start", step: 3)
            HStack(spacing: 8) {
                ForEach(Self.durations, id: \.self) { days in
                    DurationChip(days: days, isSelected: draft.durationDays == days, color: draft.category.color) {
                        withAnimation(.snappy) { draft.durationDays = days }
                    }
                }
            }
            Stepper(value: $draft.durationDays, in: 3...90) {
                Text(draft.durationDays.daysLabel)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Picker("Start", selection: $startsTomorrow) {
                Text("Start today").tag(false)
                Text("Start tomorrow").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: startsTomorrow) { _, tomorrow in
                draft.startDate = tomorrow ? Date.now.addingDays(1) : Date.now.startOfDay
            }
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle(draft.type == .oneVsOne ? "Choose your opponent" : "Invite your group", step: 4)
                Spacer()
                if draft.type == .group {
                    Text("\(draft.friendIDs.count) selected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if session.friends.isEmpty {
                Label("Add friends in the Friends tab to challenge them.", systemImage: "person.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(session.friends) { friend in
                        let selected = draft.friendIDs.contains(friend.id)
                        Button {
                            toggle(friend)
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(name: friend.name, id: friend.id, size: 40)
                                Text(friend.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selected ? Color.indigo : Color.secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: selected)

                        if friend.id != session.friends.last?.id {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                if draft.type == .group && draft.friendIDs.count < 2 {
                    Text("Pick at least 2 friends for a group challenge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Actions

    private func toggle(_ friend: Friend) {
        withAnimation(.snappy) {
            if draft.type == .oneVsOne {
                draft.friendIDs = draft.friendIDs.contains(friend.id) ? [] : [friend.id]
            } else if draft.friendIDs.contains(friend.id) {
                draft.friendIDs.remove(friend.id)
            } else {
                draft.friendIDs.insert(friend.id)
            }
        }
    }

    private func create() {
        guard isValid, !isCreating else { return }
        focus = nil
        isCreating = true
        Task {
            if await session.createChallenge(draft) != nil {
                created = true
                try? await Task.sleep(for: .milliseconds(250))
                dismiss()
            }
            isCreating = false
        }
    }
}
