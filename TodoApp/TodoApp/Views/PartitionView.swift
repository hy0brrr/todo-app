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

            Divider().opacity(0.3)

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
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }

            Divider().opacity(0.3)

            // Add task input
            addTaskBar
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private var partitionHeader: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(partition.color.color)
                .frame(width: 8, height: 8)

            Text(partition.name.isEmpty ? "Untitled" : partition.name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()

            if isHoveringHeader {
                Button {
                    onStartEdit()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onHover { hovering in
            isHoveringHeader = hovering
        }
    }

    private var addTaskBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("Add task to \(partition.name.isEmpty ? "Untitled" : partition.name)...", text: $newTaskName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit {
                    let trimmed = newTaskName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onAddTask(partition.id, trimmed)
                    newTaskName = ""
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
