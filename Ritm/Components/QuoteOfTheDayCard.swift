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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.2), in: Circle())
                .flipsForRightToLeftLayoutDirection(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(quote.text)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(isExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text("— \(quote.source)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            ShareLink(item: "“\(quote.text)”\n— \(quote.source)\n\n#Ritm") {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(Text("Share quote"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: (colors.last ?? .indigo).opacity(0.25), radius: 8, y: 4)
        .opacity(appeared ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isExpanded.toggle() }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) { appeared = true }
        }
        .id(DayKey.string(from: date))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Quote of the Day"))
        .accessibilityValue(Text("\(quote.text) — \(quote.source)"))
        .accessibilityHint(Text("Tap to read the full quote"))
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
