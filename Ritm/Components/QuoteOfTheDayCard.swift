import SwiftUI

/// A daily motivational quote on a gradient that changes color each day.
struct QuoteOfTheDayCard: View {
    let date: Date

    @State private var appeared = false
    @State private var isExpanded = false

    private static let themes: [[Color]] = [
        [Color(red: 0.98, green: 0.55, blue: 0.35), Color(red: 0.93, green: 0.30, blue: 0.48)], // sunrise
        [Color(red: 0.20, green: 0.70, blue: 0.75), Color(red: 0.25, green: 0.40, blue: 0.85)], // ocean
        [Color(red: 0.45, green: 0.35, blue: 0.95), Color(red: 0.75, green: 0.35, blue: 0.85)], // ritm
        [Color(red: 0.20, green: 0.68, blue: 0.48), Color(red: 0.10, green: 0.50, blue: 0.55)], // oasis
        [Color(red: 0.95, green: 0.68, blue: 0.25), Color(red: 0.90, green: 0.42, blue: 0.20)], // desert gold
        [Color(red: 0.30, green: 0.30, blue: 0.55), Color(red: 0.55, green: 0.30, blue: 0.60)], // night
        [Color(red: 0.90, green: 0.40, blue: 0.60), Color(red: 0.55, green: 0.35, blue: 0.90)], // bloom
    ]

    private var quote: DailyQuote { DailyQuote.forDay(date) }
    private var colors: [Color] { Self.themes[DailyQuote.themeIndex(for: date) % Self.themes.count] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .symbolEffect(.pulse, options: .repeating)
                Text("Quote of the Day")
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                ShareLink(item: "“\(quote.text)”\n— \(quote.source)\n\n#Ritm") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .padding(8)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .accessibilityLabel(Text("Share quote"))
            }
            .font(.caption.weight(.heavy))
            .foregroundStyle(.white.opacity(0.9))

            Text(quote.text)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                Capsule()
                    .fill(.white.opacity(0.7))
                    .frame(width: 22, height: 2)
                Text(quote.source)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

                // Large decorative quotation mark.
                Image(systemName: "quote.opening")
                    .font(.system(size: 110, weight: .black))
                    .foregroundStyle(.white.opacity(0.12))
                    .offset(x: 12, y: -16)
                    .flipsForRightToLeftLayoutDirection(true)

                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 160, height: 160)
                    .offset(x: 60, y: 90)
                    .blur(radius: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .shadow(color: (colors.last ?? .indigo).opacity(0.35), radius: 14, y: 8)
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isExpanded.toggle() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
        .id(DayKey.string(from: date))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Quote of the Day"))
        .accessibilityValue(Text("\(quote.text) — \(quote.source)"))
    }
}

#if DEBUG
#Preview {
    VStack {
        QuoteOfTheDayCard(date: .now)
        QuoteOfTheDayCard(date: .now.addingDays(1))
    }
    .padding()
}
#endif
