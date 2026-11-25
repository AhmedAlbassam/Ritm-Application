import SwiftUI

/// Small statistic card used on the goal detail screen.
struct StatTile: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardStyle(cornerRadius: 18)
        .accessibilityElement(children: .combine)
    }
}

/// Mock of an iOS notification banner, previewing the reminder text.
struct NotificationPreview: View {
    let title: String
    let message: String
    let time: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PREVIEW")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient.brand)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "target")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(time, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(message)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notification preview: \(title). \(message)")
    }
}
