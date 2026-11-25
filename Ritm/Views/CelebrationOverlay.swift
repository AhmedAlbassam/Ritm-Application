import SwiftUI

/// Full-screen "you did it!" moment: confetti cannons, rotating light rays,
/// a medal that springs in with a shine, haptics, and a one-tap share.
struct CelebrationOverlay: View {
    let celebration: Celebration
    let onDismiss: () -> Void

    @State private var showBackground = false
    @State private var showBadge = false
    @State private var showText = false
    @State private var showButtons = false
    @State private var confettiTrigger = 0
    @State private var badgeBounce = 0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    RadialGradient(
                        colors: [(celebration.colors.first ?? .indigo).opacity(0.85), Color.black.opacity(0.75)],
                        center: .center,
                        startRadius: 40,
                        endRadius: 520
                    )
                )
                .ignoresSafeArea()
                .opacity(showBackground ? 1 : 0)

            ConfettiView(
                colors: celebration.colors + [.yellow, .pink, .mint, .orange, .cyan, .white],
                trigger: confettiTrigger
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                Text(celebration.headline)
                    .font(.subheadline.weight(.heavy))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 12)

                ZStack {
                    SunburstView(color: .white, rayCount: 18, length: 420)
                        .opacity(showBadge ? 1 : 0)
                        .scaleEffect(showBadge ? 1 : 0.3)

                    Circle()
                        .fill((celebration.colors.first ?? .white).opacity(0.55))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)

                    BadgeView(
                        icon: celebration.icon,
                        colors: celebration.colors,
                        ringColors: celebration.ringColors,
                        size: 170,
                        animated: true
                    )
                    .symbolEffect(.bounce, value: badgeBounce)
                    .scaleEffect(showBadge ? 1 : 0.2)
                    .rotationEffect(.degrees(showBadge ? 0 : -25))
                    .opacity(showBadge ? 1 : 0)
                    .onTapGesture {
                        badgeBounce += 1
                        confettiTrigger += 1
                    }
                }
                .frame(height: 260)

                VStack(spacing: 10) {
                    Text(celebration.title)
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .multilineTextAlignment(.center)
                    Text(celebration.message)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)

                Spacer()

                VStack(spacing: 12) {
                    ShareCardButton(content: ShareCardContent(celebration: celebration)) {
                        Label("Share with Friends", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(celebration.colors.first ?? .indigo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: Capsule())
                    }

                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.18), in: Capsule())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.97))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 30)
            }
        }
        .sensoryFeedback(.success, trigger: showBadge)
        .sensoryFeedback(.impact(weight: .medium), trigger: confettiTrigger)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .task { await playEntrance() }
    }

    @MainActor
    private func playEntrance() async {
        withAnimation(.easeOut(duration: 0.3)) { showBackground = true }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { showBadge = true }
        try? await Task.sleep(for: .milliseconds(250))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showText = true }
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showButtons = true }
        try? await Task.sleep(for: .milliseconds(350))
        badgeBounce += 1
    }
}

#if DEBUG
#Preview("Achievement") {
    CelebrationOverlay(celebration: .achievement(.streak7)) {}
}

#Preview("Milestone") {
    CelebrationOverlay(celebration: .milestone(.half, goalTitle: "Walk for 30 min daily", category: .health, done: 15, target: 30)) {}
}
#endif
