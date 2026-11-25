import SwiftUI

/// Circular progress ring with an angular gradient and an animated fill.
struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var colors: [Color]
    var trackColor: Color? = nil

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor ?? (colors.last ?? .gray).opacity(0.15), lineWidth: lineWidth)

            if clamped > 0 {
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(
                        AngularGradient(
                            colors: colors,
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * clamped)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: clamped)
        .accessibilityElement()
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}

/// Rounded linear progress bar.
struct LinearProgressBar: View {
    var progress: Double
    var color: Color
    var height: CGFloat = 8

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, proxy.size.width * clamped))
                    .opacity(clamped > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: clamped)
        .accessibilityHidden(true)
    }
}
