import SwiftUI
import UIKit

/// Profile photos available to every avatar in the app, keyed by user ID.
private struct ProfilePhotosKey: EnvironmentKey {
    static let defaultValue: [String: UIImage] = [:]
}

extension EnvironmentValues {
    var profilePhotos: [String: UIImage] {
        get { self[ProfilePhotosKey.self] }
        set { self[ProfilePhotosKey.self] = newValue }
    }
}

/// A person's profile photo, or their initials on a color picked from their ID.
struct AvatarView: View {
    let name: String
    let id: String
    var size: CGFloat = 44
    /// Overrides the stored photo (used for the Edit Profile preview).
    var image: UIImage?
    /// False shows initials even if a photo exists.
    var showsPhoto = true

    @Environment(\.profilePhotos) private var photos

    private static let palettes: [[Color]] = [
        [.pink, .orange], [.blue, .cyan], [.purple, .indigo], [.green, .mint],
        [.orange, .yellow], [.teal, .blue], [.red, .pink], [.indigo, .purple],
    ]

    private var colors: [Color] {
        // Stable across launches (unlike `hashValue`).
        let sum = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palettes[sum % Self.palettes.count]
    }

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    var body: some View {
        Group {
            if showsPhoto, let photo = image ?? photos[id] {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: max(1, size * 0.04)))
        .accessibilityLabel(Text(name))
    }
}
