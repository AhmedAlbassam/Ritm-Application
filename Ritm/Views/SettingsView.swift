import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notifications
    @Environment(SessionStore.self) private var session
    @State private var confirmSignOut = false
    @State private var confirmDelete = false
    @State private var isDeleting = false

    private var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? code
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient.brand)
                            .frame(width: 64, height: 64)
                            .overlay(RitmLogo(height: 34))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ritm")
                                .font(.title3.weight(.bold))
                            Text("Build your daily rhythm")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if let user = session.user {
                    Section {
                        HStack(spacing: 14) {
                            AvatarView(name: user.name, id: user.id, size: 48)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name)
                                    .font(.headline)
                                if session.isDemo {
                                    Text("Demo account")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        NavigationLink {
                            ProfileView(userID: user.id)
                        } label: {
                            Label("My Profile", systemImage: "person.crop.circle.fill")
                        }
                        LabeledContent {
                            Text(user.email)
                        } label: {
                            Label("Email", systemImage: "envelope.fill")
                        }
                        LabeledContent {
                            Text(user.phone)
                        } label: {
                            Label("Phone", systemImage: "phone.fill")
                        }
                        LabeledContent {
                            Text(user.age, format: .number)
                        } label: {
                            Label("Age", systemImage: "birthday.cake.fill")
                        }
                        Button {
                            confirmSignOut = true
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            if isDeleting {
                                ProgressView()
                            } else {
                                Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
                            }
                        }
                        .disabled(isDeleting)
                    } header: {
                        Text("Account")
                    }
                }

                Section {
                    Button {
                        openAppSettings()
                    } label: {
                        HStack {
                            Label("App Language", systemImage: "globe")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(currentLanguageName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Choose English or العربية for Ritm in the iOS Settings app. In Arabic, the whole app switches to a right-to-left layout.")
                }

                Section {
                    HStack {
                        Label("Reminders", systemImage: "bell.badge.fill")
                        Spacer()
                        if notifications.isAuthorized {
                            Text("Allowed").foregroundStyle(.green)
                        } else if notifications.isDenied {
                            Text("Off").foregroundStyle(.orange)
                        } else {
                            Text("Not set up").foregroundStyle(.secondary)
                        }
                    }
                    if notifications.isDenied {
                        Button("Turn On in Settings") { notifications.openSystemSettings() }
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    HStack {
                        Label("Widgets", systemImage: "square.grid.2x2.fill")
                        Spacer()
                        if SharedStore.isUsingAppGroup {
                            Text("Connected").foregroundStyle(.green)
                        } else {
                            Text("Not connected").foregroundStyle(.orange)
                        }
                    }
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    if !SharedStore.isUsingAppGroup {
                        Text("Widgets need the App Group capability. See the README for the one-time setup in Xcode.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await notifications.refreshAuthorizationStatus() }
            .confirmationDialog("Log out of Ritm?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    dismiss()
                    session.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your personal goals stay on this device.")
            }
            .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) { deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your Ritm account, profile and friendships. This can't be undone.")
            }
        }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            do {
                try await session.deleteAccount()
                dismiss()
            } catch {
                session.errorMessage = error.localizedDescription
            }
            isDeleting = false
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
