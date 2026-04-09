import SwiftUI

struct PartitionView: View {
    let partition: Partition
    let tasks: [TodoTask]
    let isEditing: Bool
    let onAddTask: (String, String) -> Void
    let onToggleComplete: (String) -> Void
    let onToggleStar: (String) -> Void
    let onSetDueDate: (String, Date?) -> Void
    let onRename: (String, String) -> Void
    let onStartEdit: () -> Void
    let onSaveEdit: (String, PartitionColor) -> Void

    @State private var newTaskName: String = ""
    @State private var isHoveringHeader = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if isEditing {
                PartitionEditView(partition: partition, onSave: onSaveEdit)
                Divider().opacity(DesignTokens.Stroke.dividerOpacity)
            } else {
                partitionHeader
            }

            // Task list
            ScrollView {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskItemView(
                                task: task,
                                onToggleComplete: onToggleComplete,
                                onToggleStar: onToggleStar,
                                onSetDueDate: onSetDueDate,
                                onRename: onRename
                            )
                        }
                    }

                    if tasks.isEmpty {
                        Text("No tasks yet.")
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

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Add task input
            addTaskBar
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
        .zIndex(isHoveringHeader ? 10 : 0)
    }

    private var partitionHeader: some View {
        VStack(spacing: DesignTokens.Spacing.cardHeaderRuleGap) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.cardHeaderGap) {
                partitionTitleTag

                Spacer(minLength: 0)
            }
            .padding(.leading, DesignTokens.Spacing.partitionHeaderContentLeadingInset)

            headerRule
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.top, DesignTokens.Spacing.cardHeaderTop)
        .padding(.bottom, DesignTokens.Spacing.cardHeaderBottom)
        .overlay(alignment: .topTrailing) {
            headerSettingsButton
                .padding(.top, DesignTokens.Spacing.cardHeaderTop - 2)
                .padding(.trailing, DesignTokens.Spacing.sectionPaddingHorizontal)
                .opacity(isHoveringHeader ? 1 : 0)
                .scaleEffect(isHoveringHeader ? 1 : 0.94, anchor: .topTrailing)
                .allowsHitTesting(isHoveringHeader)
                .zIndex(20)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHoveringHeader = hovering
        }
        .animation(.easeOut(duration: DesignTokens.Motion.quick), value: isHoveringHeader)
    }

    private var headerRule: some View {
        Rectangle()
            .fill(DesignTokens.ColorRole.headerRule)
            .frame(height: DesignTokens.Stroke.headerRuleLineWidth)
    }

    private var partitionTitleTag: some View {
        LiquidGlassTag(text: partition.name.isEmpty ? "Untitled" : partition.name)
    }

    private var headerSettingsButton: some View {
        Button {
            onStartEdit()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(DesignTokens.Typography.icon)
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.pill, style: .continuous)
                        .fill(DesignTokens.ColorRole.pillBackground)
                )
        }
        .buttonStyle(.plain)
    }

    private var addTaskBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(DesignTokens.Typography.icon)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)

            TextField(
                "",
                text: $newTaskName,
                prompt: Text("Add task to \(partition.name.isEmpty ? "Untitled" : partition.name)...")
                    .foregroundStyle(DesignTokens.ColorRole.tertiaryText)
            )
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .onSubmit {
                    let trimmed = newTaskName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onAddTask(partition.id, trimmed)
                    newTaskName = ""
                }
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.vertical, 10)
        .background(DesignTokens.ColorRole.footerBackground)
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
                        .fill(Color.white.opacity(0.08))

                    cardShape
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PartitionView(
        partition: Partition(name: "Work", color: .blue),
        tasks: [
            TodoTask(partitionId: "p1", name: "整理第二季度产品需求", isStarred: true),
            TodoTask(partitionId: "p1", name: "更新路线图", dueDate: Date()),
        ],
        isEditing: false,
        onAddTask: { _, _ in },
        onToggleComplete: { _ in },
        onToggleStar: { _ in },
        onSetDueDate: { _, _ in },
        onRename: { _, _ in },
        onStartEdit: {},
        onSaveEdit: { _, _ in }
    )
    .frame(width: 350, height: 250)
    .padding()
}
