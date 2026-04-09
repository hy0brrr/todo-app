import SwiftUI

struct CompletedSectionView: View {
    let tasks: [TodoTask]
    let onToggleComplete: (String) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            decorativeEmoji

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top, spacing: DesignTokens.Spacing.cardHeaderGap) {
                    LiquidGlassTag(text: "Completed")

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
                .padding(.top, DesignTokens.Spacing.cardHeaderTop)
                .padding(.bottom, DesignTokens.Spacing.cardHeaderBottom)

                Divider().opacity(DesignTokens.Stroke.dividerOpacity)

                // Completed tasks list
                ScrollView {
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

    private var decorativeEmoji: some View {
        Text("☁️")
            .font(DesignTokens.Typography.emoji)
            .frame(width: DesignTokens.Size.emojiPlate, height: DesignTokens.Size.emojiPlate)
            .padding(.top, DesignTokens.Spacing.cardHeaderTop)
            .padding(.trailing, DesignTokens.Spacing.sectionPaddingHorizontal)
            .allowsHitTesting(false)
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
