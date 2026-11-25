import SwiftUI

/// A round medal: tier-colored outer ring, gradient face, symbol, optional shine sweep.
struct BadgeView: View {
    let icon: String
    let colors: [Color]
    let ringColors: [Color]
    var size: CGFloat = 80
    var isLocked = false
    var animated = false

    @State private var shine = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AngularGradient(colors: ringColors + [ringColors.first ?? .white], center: .center))
            Circle()
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(size * 0.08)
            Circle()
                .strokeBorder(.white.opacity(0.35), lineWidth: max(1, size * 0.02))
                .padding(size * 0.15)
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: size * 0.03, y: size * 0.02)
        }
        .overlay {
            if animated && !isLocked {
                LinearGradient(colors: [.clear, .white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(width: size * 0.3, height: size * 1.6)
                    .rotationEffect(.degrees(25))
                    .offset(x: shine ? size : -size)
                    .blendMode(.plusLighter)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.8).delay(0.6).repeatForever(autoreverses: false)) {
                            shine = true
                        }
                    }
            }
        }
        .clipShape(Circle())
        .frame(width: size, height: size)
        .saturation(isLocked ? 0 : 1)
        .opacity(isLocked ? 0.4 : 1)
        .overlay(alignment: .bottomTrailing) {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(size * 0.07)
                    .background(Color.secondary, in: Circle())
                    .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 2))
            }
        }
        .shadow(color: (colors.first ?? .clear).opacity(isLocked ? 0 : 0.45), radius: size * 0.12, y: size * 0.06)
        .accessibilityHidden(true)
    }
}

extension BadgeView {
    init(achievement: Achievement, size: CGFloat = 80, isLocked: Bool = false, animated: Bool = false) {
        self.init(
            icon: achievement.icon,
            colors: achievement.colors,
            ringColors: achievement.tier.ringColors,
            size: size,
            isLocked: isLocked,
            animated: animated
        )
    }
}

/// Slowly rotating light rays behind a badge.
struct SunburstView: View {
    var color: Color = .white
    var rayCount = 16
    var length: CGFloat = 360

    @State private var rotate = false

    var body: some View {
        ZStack {
            ForEach(0..<rayCount, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(
                        colors: [.clear, color.opacity(0.28), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: length * 0.05, height: length)
                    .rotationEffect(.degrees(Double(index) * 180 / Double(rayCount)))
            }
        }
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
        .accessibilityHidden(true)
    }
}

/// The "رتم" wordmark, tintable.
struct RitmLogo: View {
    var height: CGFloat = 40
    var color: Color = .white

    var body: some View {
        Image("Wordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .foregroundStyle(color)
            .accessibilityLabel(Text("Ritm"))
    }
}
