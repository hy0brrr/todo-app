import SwiftUI

struct CompletedSectionView: View {
    @Environment(\.interfaceDensity) private var density

    let groups: [CompletedTaskGroup]
    let onSaveTask: (String, String) -> Void
    let onAddChildTask: (String, String) -> Void
    let onToggleComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignTokens.Spacing.scaledCardHeaderRuleGap(in: density)) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.scaledCardHeaderGap(in: density)) {
                    LiquidGlassTag(text: "Completed")

                    Spacer(minLength: 0)
                }
                .padding(.leading, DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density))

                headerRule
            }
            .padding(.horizontal, DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density))
            .padding(.top, DesignTokens.Spacing.scaledCardHeaderTop(in: density))
            .padding(.bottom, DesignTokens.Spacing.scaledCardHeaderBottom(in: density))

            // Completed tasks list
            if groups.isEmpty {
                EmptyTodoPlaceholderView()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        LazyVStack(spacing: DesignTokens.scaled(6, in: density)) {
                            ForEach(groups) { group in
                                VStack(spacing: 0) {
                                    TaskItemView(
                                        task: group.rootTask,
                                        depth: 0,
                                        renderMode: .completed,
                                        allowsCompletionToggle: group.allowsRootCompletionToggle,
                                        onSaveTask: onSaveTask,
                                        onBeginAddChildTask: { _ in },
                                        onToggleComplete: onToggleComplete,
                                        onToggleStar: { _ in },
                                        onSetDueDate: { _, _ in }
                                    )

                                    ForEach(group.completedChildren) { child in
                                        TaskItemView(
                                            task: child,
                                            depth: 1,
                                            renderMode: .completed,
                                            allowsCompletionToggle: true,
                                            onSaveTask: onSaveTask,
                                            onBeginAddChildTask: { _ in },
                                            onToggleComplete: onToggleComplete,
                                            onToggleStar: { _ in },
                                            onSetDueDate: { _, _ in }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, DesignTokens.Spacing.scaledSectionBodyTop(in: density))
                }
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous))
        .overlay {
            if #unavailable(macOS 26.0) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous)
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.scaledCardLineWidth(in: density))
            }
        }
        .shadow(
            color: .black.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            y: DesignTokens.Shadow.cardYOffset
        )
    }

    private var cardBackground: some View {
        let cardShape = RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous)

        return ZStack {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: cardShape)
                    .environment(\.appearsActive, true)

                cardShape
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.scaledCardLineWidth(in: density))
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
            .frame(height: DesignTokens.Stroke.scaledHeaderRuleLineWidth(in: density))
    }
}

// MARK: - Preview

#Preview {
    CompletedSectionView(
        groups: [
            CompletedTaskGroup(
                rootTask: TodoTask(partitionId: "p1", name: "写周报", tags: ["Weekly"], isCompleted: true, completedAt: Date()),
                completedChildren: [],
                showsParentContext: false
            ),
            CompletedTaskGroup(
                rootTask: TodoTask(partitionId: "p2", name: "预订机票", tags: ["Travel"]),
                completedChildren: [
                    TodoTask(partitionId: "p2", name: "比较航班价格", parentTaskId: "t2", isCompleted: true, completedAt: Date())
                ],
                showsParentContext: true
            )
        ],
        onSaveTask: { _, _ in },
        onAddChildTask: { _, _ in },
        onToggleComplete: { _ in }
    )
    .frame(width: 350, height: 200)
    .padding()
}
