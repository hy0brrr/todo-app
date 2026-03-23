import SwiftUI

struct ContentView: View {
    @Environment(TodoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            // Partition cards + Completed section
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.partitions) { partition in
                        PartitionView(
                            partition: partition,
                            tasks: viewModel.activeTasks(for: partition.id),
                            isEditing: viewModel.editingPartitionId == partition.id,
                            onAddTask: { pid, name in viewModel.addTask(partitionId: pid, name: name) },
                            onToggleComplete: { viewModel.toggleComplete($0) },
                            onToggleStar: { viewModel.toggleStar($0) },
                            onSetDueDate: { id, date in viewModel.setDueDate(id, date: date) },
                            onRename: { id, name in viewModel.renameTask(id, name: name) },
                            onStartEdit: { viewModel.editingPartitionId = partition.id },
                            onSaveEdit: { name, color in viewModel.savePartitionEdit(id: partition.id, name: name, color: color) }
                        )
                        .frame(height: partition.height)

                        // Drag handle to resize partition
                        PartitionDragHandle { delta in
                            viewModel.updatePartitionHeight(partition.id, height: partition.height + delta)
                        }
                    }

                    CompletedSectionView(
                        tasks: viewModel.completedTasks,
                        onToggleComplete: { viewModel.toggleComplete($0) }
                    )
                    .frame(minHeight: 120)
                }
                .padding(12)
            }
        }
        .frame(minWidth: 300, idealWidth: 380, maxWidth: 500, minHeight: 500)
        .sheet(isPresented: $viewModel.showManagePartitions) {
            ManagePartitionsView(
                partitions: $viewModel.partitions,
                onDelete: { viewModel.deletePartition($0) },
                onDismiss: { viewModel.showManagePartitions = false }
            )
        }
    }
}

// MARK: - Partition Drag Handle

struct PartitionDragHandle: View {
    let onDrag: (CGFloat) -> Void

    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(isHovering ? Color.blue.opacity(0.2) : Color.clear)
            .frame(height: 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onDrag(value.translation.height)
                    }
            )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(TodoViewModel())
        .frame(width: 400, height: 750)
}
