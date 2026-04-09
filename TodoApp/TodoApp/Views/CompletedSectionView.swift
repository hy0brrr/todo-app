import SwiftUI

struct CompletedSectionView: View {
    let tasks: [TodoTask]
    let onToggleComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignTokens.Spacing.cardHeaderRuleGap) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.cardHeaderGap) {
                    LiquidGlassTag(text: "Completed")

                    Spacer(minLength: 0)
                }
                .padding(.leading, DesignTokens.Spacing.partitionHeaderContentLeadingInset)

                headerRule
            }
            .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
            .padding(.top, DesignTokens.Spacing.cardHeaderTop)
            .padding(.bottom, DesignTokens.Spacing.cardHeaderBottom)

            // Completed tasks list
            ScrollView {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskItemView(
                                task: task,
                                onToggleComplete: onToggleComplete,
                                onToggleStar: { _ in },
                                onSetDueDate: { _, _ in },
                                onRename: { _, _ in }
                            )
                        }
                    }

                    if tasks.isEmpty {
                        Text("No completed tasks.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                            .italic()
                            .padding(.horizontal, DesignTokens.Spacing.listEmptyHorizontal)
                            .padding(.vertical, DesignTokens.Spacing.listEmptyVertical)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, DesignTokens.Spacing.sectionBodyTop)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay {
            if #unavailable(macOS 26.0) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.cardLineWidth)
            }
        }
        .shadow(
            color: .black.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            y: DesignTokens.Shadow.cardYOffset
        )
    }

    private var cardBackground: some View {
        let cardShape = RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)

        return ZStack {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: cardShape)
                    .environment(\.appearsActive, true)

                cardShape
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.cardLineWidth)
            } else {
                ZStack {
                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.ColorRole.cardBackgroundTop,
                                    DesignTokens.ColorRole.cardBackgroundBottom
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    cardShape
                        .fill(Color.white.opacity(0.04))

                    cardShape
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }

    private var headerRule: some View {
        Rectangle()
            .fill(DesignTokens.ColorRole.headerRule)
            .frame(height: DesignTokens.Stroke.headerRuleLineWidth)
    }
}

// MARK: - Preview

#Preview {
    CompletedSectionView(
        tasks: [
            TodoTask(partitionId: "p1", name: "写周报", isCompleted: true, completedAt: Date()),
            TodoTask(partitionId: "p2", name: "预订机票", isCompleted: true, completedAt: Date()),
        ],
        onToggleComplete: { _ in }
    )
    .frame(width: 350, height: 200)
    .padding()
}
