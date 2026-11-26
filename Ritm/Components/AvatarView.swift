import SwiftUI

/// Circle with a person's initials on a color picked from their ID, so it stays the same everywhere.
struct AvatarView: View {
    let name: String
    let id: String
    var size: CGFloat = 44

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
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: max(1, size * 0.04)))
            .accessibilityLabel(Text(name))
    }
}
