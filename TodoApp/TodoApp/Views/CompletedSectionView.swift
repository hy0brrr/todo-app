import SwiftUI

struct CompletedSectionView: View {
    let tasks: [TodoTask]
    let onToggleComplete: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)

                Text("Completed")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().opacity(0.3)

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
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    CompletedSectionView(
        tasks: [
            TodoTask(partitionId: "p1", name: "Write weekly report", isCompleted: true, completedAt: Date()),
            TodoTask(partitionId: "p2", name: "Book flight tickets", isCompleted: true, completedAt: Date()),
        ],
        onToggleComplete: { _ in }
    )
    .frame(width: 350, height: 200)
    .padding()
}
