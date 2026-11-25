import SwiftUI

/// What goes on a shareable image.
struct ShareCardContent {
    var headline: String
    var title: String
    var message: String
    var icon: String
    var colors: [Color]
    var ringColors: [Color]
    /// When set, the card shows a progress ring instead of a medal.
    var progress: Double?
    var footnote: String?
    var shareText: String

    init(celebration: Celebration) {
        headline = celebration.headline
        title = celebration.title
        message = celebration.message
        icon = celebration.icon
        colors = celebration.colors
        ringColors = celebration.ringColors
        progress = nil
        footnote = celebration.date.formatted(date: .long, time: .omitted)
        shareText = celebration.shareText
    }

    init(headline: String, title: String, message: String, icon: String, colors: [Color], ringColors: [Color], progress: Double? = nil, footnote: String? = nil, shareText: String) {
        self.headline = headline
        self.title = title
        self.message = message
        self.icon = icon
        self.colors = colors
        self.ringColors = ringColors
        self.progress = progress
        self.footnote = footnote
        self.shareText = shareText
    }
}

/// A 4:5 card (1080 × 1350 px when rendered at 3×) for Instagram, WhatsApp, Messages…
struct ShareCardView: View {
    let content: ShareCardContent

    static let size = CGSize(width: 360, height: 450)

    // Fixed decorative confetti so the rendered image is deterministic.
    private static let dots: [(CGFloat, CGFloat, CGFloat, Double, Int)] = [
        (0.08, 0.10, 10, 20, 0), (0.88, 0.14, 8, -30, 1), (0.16, 0.34, 6, 45, 2), (0.92, 0.38, 11, 10, 3),
        (0.06, 0.62, 9, -15, 4), (0.94, 0.66, 7, 60, 0), (0.22, 0.86, 8, 30, 1), (0.80, 0.90, 10, -45, 2),
        (0.50, 0.06, 7, 15, 3), (0.70, 0.24, 6, -60, 4), (0.30, 0.18, 7, 75, 0), (0.62, 0.80, 6, 20, 3),
    ]
    private static let dotColors: [Color] = [.yellow, .pink, .mint, .orange, .cyan]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [content.colors.first ?? .indigo, (content.colors.last ?? .purple), Color(red: 0.12, green: 0.08, blue: 0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(Self.dots.indices, id: \.self) { index in
                let dot = Self.dots[index]
                RoundedRectangle(cornerRadius: 2)
                    .fill(Self.dotColors[dot.4].opacity(0.85))
                    .frame(width: dot.2, height: dot.2 * 0.6)
                    .rotationEffect(.degrees(dot.3))
                    .position(x: Self.size.width * dot.0, y: Self.size.height * dot.1)
            }

            VStack(spacing: 14) {
                RitmLogo(height: 44)
                    .padding(.top, 26)

                Spacer(minLength: 0)

                ZStack {
                    SunburstView(color: .white, rayCount: 12, length: 230)
                        .opacity(0.8)
                    if let progress = content.progress {
                        ZStack {
                            Circle().fill(.white.opacity(0.12))
                            ProgressRing(progress: progress, lineWidth: 14, colors: [.white.opacity(0.7), .white], trackColor: .white.opacity(0.2))
                            VStack(spacing: 2) {
                                Image(systemName: content.icon)
                                    .font(.system(size: 26, weight: .bold))
                                Text(progress, format: .percent.precision(.fractionLength(0)))
                                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(.white)
                        }
                        .frame(width: 150, height: 150)
                    } else {
                        BadgeView(icon: content.icon, colors: content.colors, ringColors: content.ringColors, size: 150)
                    }
                }
                .frame(height: 190)

                VStack(spacing: 6) {
                    Text(content.headline)
                        .font(.caption.weight(.heavy))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .opacity(0.85)
                    Text(content.title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(content.message)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                    Text("Build your daily rhythm with Ritm")
                    if let footnote = content.footnote {
                        Text("·")
                        Text(footnote)
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.bottom, 22)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }
}

@MainActor
enum ShareCardRenderer {
    /// Renders the card to an image, carrying over the caller's language and layout direction.
    static func image(for content: ShareCardContent, locale: Locale, layoutDirection: LayoutDirection) -> Image? {
        let renderer = ImageRenderer(
            content: ShareCardView(content: content)
                .environment(\.locale, locale)
                .environment(\.layoutDirection, layoutDirection)
        )
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

/// A "Share" button that renders the card lazily and opens the system share sheet.
struct ShareCardButton<Label: View>: View {
    let content: ShareCardContent
    @ViewBuilder var label: () -> Label

    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var image: Image?

    var body: some View {
        Group {
            if let image {
                ShareLink(
                    item: image,
                    message: Text(content.shareText),
                    preview: SharePreview(content.title, image: image),
                    label: label
                )
            } else {
                label().opacity(0.5)
            }
        }
        .task(id: content.title + content.message) {
            image = ShareCardRenderer.image(for: content, locale: locale, layoutDirection: layoutDirection)
        }
    }
}
