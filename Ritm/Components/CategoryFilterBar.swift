import SwiftUI

/// Horizontally scrolling category filter (All, Health, Work, …).
struct CategoryFilterBar: View {
    @Binding var selection: GoalCategory?
    let counts: [GoalCategory: Int]
    let totalCount: Int

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: String(localized: "All"),
                    icon: "square.grid.2x2.fill",
                    color: .indigo,
                    count: totalCount,
                    isSelected: selection == nil
                ) {
                    selection = nil
                }

                ForEach(GoalCategory.allCases) { category in
                    CategoryChip(
                        title: category.title,
                        icon: category.icon,
                        color: category.color,
                        count: counts[category] ?? 0,
                        isSelected: selection == category
                    ) {
                        selection = selection == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16) // let the chips scroll edge to edge
        .sensoryFeedback(.selection, trigger: selection)
    }
}
