import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Edit photo, bio, favorite habit and showcase badges.
struct EditProfileView: View {
    enum Field: Hashable { case bio, habit }

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AchievementRecord.unlockedAt, order: .reverse) private var records: [AchievementRecord]
    @FocusState private var focus: Field?

    private let profile: PublicProfile

    @State private var bio: String
    @State private var favoriteHabit: String
    @State private var favoriteCategory: GoalCategory?
    @State private var showcase: [String]
    @State private var photoChange: ProfileUpdate.PhotoChange = .keep
    @State private var previewImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var isSaving = false
    @State private var limitHit = 0

    init(profile: PublicProfile) {
        self.profile = profile
        _bio = State(initialValue: profile.bio)
        _favoriteHabit = State(initialValue: profile.favoriteHabit)
        _favoriteCategory = State(initialValue: profile.favoriteCategory)
        _showcase = State(initialValue: profile.showcase)
    }

    /// Badges you've earned, newest first.
    private var earned: [Achievement] {
        records.compactMap { record -> Achievement? in
            guard record.key.hasPrefix(AchievementRecord.achievementPrefix) else { return nil }
            return Achievement(rawValue: String(record.key.dropFirst(AchievementRecord.achievementPrefix.count)))
        }
    }

    private var hasPhoto: Bool {
        switch photoChange {
        case .set: true
        case .remove: false
        case .keep: profile.photo != nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    photoSection
                    bioSection
                    habitSection
                    showcaseSection
                }
                .padding(16)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save", action: save)
                            .fontWeight(.semibold)
                            .disabled(isProcessingPhoto)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                loadPhoto(item)
            }
            .sensoryFeedback(.warning, trigger: limitHit)
        }
    }

    // MARK: Photo

    private var photoSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(name: profile.name, id: profile.id, size: 120, image: previewImage, showsPhoto: hasPhoto)
                .overlay {
                    if isProcessingPhoto {
                        Circle().fill(.black.opacity(0.35))
                        ProgressView().tint(.white)
                    }
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(LinearGradient.brand, in: Circle())
                        .overlay(Circle().strokeBorder(Color(.systemGroupedBackground), lineWidth: 3))
                }
                .accessibilityLabel(Text("Choose a profile photo"))
            }

            HStack(spacing: 16) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    if hasPhoto {
                        Text("Change Photo")
                    } else {
                        Text("Add Photo")
                    }
                }
                .font(.subheadline.weight(.semibold))

                if hasPhoto {
                    Button("Remove", role: .destructive) {
                        withAnimation(.snappy) {
                            photoChange = .remove
                            previewImage = nil
                            pickerItem = nil
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .tint(.indigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Bio

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.headline)
            TextField("Write a little about yourself…", text: $bio, axis: .vertical)
                .lineLimit(3...5)
                .focused($focus, equals: .bio)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onChange(of: bio) { _, newValue in
                    if newValue.count > PublicProfile.bioLimit {
                        bio = String(newValue.prefix(PublicProfile.bioLimit))
                        limitHit += 1
                    }
                }
            HStack {
                Spacer()
                Text("\(bio.count)/\(PublicProfile.bioLimit)")
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(bio.count >= PublicProfile.bioLimit ? Color.orange : Color.secondary)
            }
        }
    }

    // MARK: Favorite habit

    private var habitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Favorite Habit")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(GoalCategory.allCases) { category in
                        CategoryChip(
                            title: category.title,
                            icon: category.icon,
                            color: category.color,
                            isSelected: favoriteCategory == category
                        ) {
                            withAnimation(.snappy) {
                                favoriteCategory = favoriteCategory == category ? nil : category
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)
            .sensoryFeedback(.selection, trigger: favoriteCategory)

            TextField("e.g., Morning walk", text: $favoriteHabit)
                .focused($focus, equals: .habit)
                .submitLabel(.done)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onChange(of: favoriteHabit) { _, newValue in
                    if newValue.count > 40 { favoriteHabit = String(newValue.prefix(40)) }
                }
        }
    }

    // MARK: Showcase

    private var showcaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Showcase Badges")
                    .font(.headline)
                Spacer()
                Text("\(showcase.count)/\(PublicProfile.showcaseLimit)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if earned.isEmpty {
                Label("Earn badges in the Achievements tab to show them here.", systemImage: "trophy")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(earned) { achievement in
                        let order = showcase.firstIndex(of: achievement.rawValue)
                        Button {
                            toggleShowcase(achievement)
                        } label: {
                            VStack(spacing: 6) {
                                BadgeView(achievement: achievement, size: 62)
                                    .overlay(alignment: .topTrailing) {
                                        if let order {
                                            Text(order + 1, format: .number)
                                                .font(.caption2.weight(.heavy))
                                                .foregroundStyle(.white)
                                                .frame(width: 22, height: 22)
                                                .background(Color.indigo, in: Circle())
                                                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                                                .transition(.scale)
                                        }
                                    }
                                Text(achievement.title)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(order != nil ? Color.indigo.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(order != nil ? Color.indigo : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.94))
                        .sensoryFeedback(.selection, trigger: order)
                    }
                }
                Text("Tap to pick up to 3, in the order you want them shown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func toggleShowcase(_ achievement: Achievement) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = showcase.firstIndex(of: achievement.rawValue) {
                showcase.remove(at: index)
            } else if showcase.count < PublicProfile.showcaseLimit {
                showcase.append(achievement.rawValue)
            } else {
                limitHit += 1
            }
        }
    }

    // MARK: Actions

    private func loadPhoto(_ item: PhotosPickerItem) {
        isProcessingPhoto = true
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let prepared = ProfilePhotoProcessor.prepare(data),
               let image = UIImage(data: prepared) {
                withAnimation(.spring) {
                    previewImage = image
                    photoChange = .set(prepared)
                }
            } else {
                session.errorMessage = String(localized: "That photo couldn't be loaded. Please try another one.")
            }
            isProcessingPhoto = false
        }
    }

    private func save() {
        focus = nil
        isSaving = true
        let update = ProfileUpdate(
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteHabit: favoriteHabit.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteCategory: favoriteCategory,
            // Drop showcased badges that are no longer earned on this device.
            showcase: showcase.filter { id in earned.contains { $0.rawValue == id } || profile.showcase.contains(id) },
            photo: photoChange
        )
        Task {
            if await session.updateProfile(update) {
                dismiss()
            }
            isSaving = false
        }
    }
}

/// Crops a photo to a centered square and shrinks it to a small JPEG
/// so it can be stored directly with the profile.
enum ProfilePhotoProcessor {
    static let pixelSize: CGFloat = 320

    static func prepare(_ data: Data) -> Data? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let canvas = CGSize(width: pixelSize, height: pixelSize)
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)

        let scale = pixelSize / min(image.size.width, image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: (pixelSize - drawSize.width) / 2, y: (pixelSize - drawSize.height) / 2)

        let squared = renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
        return squared.jpegData(compressionQuality: 0.72)
    }
}
