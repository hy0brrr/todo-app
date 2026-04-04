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
            } else {
                partitionHeader
            }

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Task list
            ScrollView {
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
    }

    private var partitionHeader: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.cardHeaderGap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.cardTitleGap) {
                Text(partition.name.isEmpty ? "Untitled" : partition.name)
                    .font(DesignTokens.Typography.partitionHeader)
                    .foregroundStyle(DesignTokens.ColorRole.primaryText)

                Text("\(tasks.count) items")
                    .font(DesignTokens.Typography.partitionMeta)
                    .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                    .padding(.horizontal, DesignTokens.Spacing.titlePillHorizontal)
                    .padding(.vertical, DesignTokens.Spacing.titlePillVertical)
                    .background(
                        Capsule()
                            .fill(DesignTokens.ColorRole.pillBackground)
                    )
            }
            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(partition.color.emoji)
                    .font(DesignTokens.Typography.emoji)
                    .frame(width: DesignTokens.Size.emojiPlate, height: DesignTokens.Size.emojiPlate)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.emojiPlate, style: .continuous)
                            .fill(DesignTokens.ColorRole.emojiPlateBackground)
                    )

                if isHoveringHeader {
                    Button {
                        onStartEdit()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(DesignTokens.Typography.icon)
                            .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.ColorRole.pillBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.vertical, DesignTokens.Spacing.sectionPaddingVerticalRelaxed)
        .onHover { hovering in
            isHoveringHeader = hovering
        }
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
            TodoTask(partitionId: "p1", name: "Q3 Product PRD", isStarred: true),
            TodoTask(partitionId: "p1", name: "Update roadmap", dueDate: Date()),
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
