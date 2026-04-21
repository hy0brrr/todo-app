import SwiftUI

struct CompletedSectionView: View {
    let groups: [CompletedTaskGroup]
    let onSaveTask: (String, String) -> Void
    let onAddChildTask: (String, String) -> Void
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
            if groups.isEmpty {
                EmptyTodoPlaceholderView()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        LazyVStack(spacing: 6) {
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
                    .padding(.top, DesignTokens.Spacing.sectionBodyTop)
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
