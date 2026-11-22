import SwiftUI

/// Filter chip used in the Today screen's horizontal category bar.
struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.25) : color.opacity(0.15), in: Capsule())
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                in: Capsule()
            )
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Color(.separator).opacity(0.5), lineWidth: 0.5))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.95))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Large tappable tile for choosing a category in the Add / Edit sheet.
struct CategoryTile: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : category.color)
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? AnyShapeStyle(category.color.gradient) : AnyShapeStyle(category.color.opacity(0.14)),
                        in: Circle()
                    )
                Text(category.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isSelected ? category.color : Color.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? category.color.opacity(0.1) : Color(.tertiarySystemFill).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? category.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Preset day-count chip ("30 days") in the Add / Edit sheet.
struct DurationChip: View {
    let days: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                Text("days")
                    .font(.caption2.weight(.medium))
                    .opacity(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.92))
        .accessibilityLabel("\(days) days")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
