import Foundation
import SwiftUI

@Observable
class TodoViewModel {
    var partitions: [Partition]
    var tasks: [TodoTask]
    var editingPartitionId: String? = nil
    var showManagePartitions: Bool = false
    var sidebarWidth: CGFloat = 320

    init() {
        let today = Calendar.current.startOfDay(for: Date())

        self.partitions = [
            Partition(id: "p1", name: "Work", color: .blue, height: 200),
            Partition(id: "p2", name: "Life", color: .green, height: 200),
        ]

        self.tasks = [
            TodoTask(id: "t1", partitionId: "p1", name: "Q3 Product PRD", isCompleted: false, isStarred: true, dueDate: nil, createdAt: Date().addingTimeInterval(-10)),
            TodoTask(id: "t2", partitionId: "p1", name: "Update roadmap", isCompleted: false, isStarred: false, dueDate: today, createdAt: Date().addingTimeInterval(-5)),
            TodoTask(id: "t3", partitionId: "p1", name: "Sync with design", isCompleted: false, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-2)),
            TodoTask(id: "t4", partitionId: "p2", name: "Buy groceries", isCompleted: false, isStarred: true, dueDate: nil, createdAt: Date().addingTimeInterval(-8)),
            TodoTask(id: "t5", partitionId: "p2", name: "Pick up laundry", isCompleted: false, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-4)),
            TodoTask(id: "t6", partitionId: "p1", name: "Write weekly report", isCompleted: true, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-20), completedAt: Date().addingTimeInterval(-1)),
            TodoTask(id: "t7", partitionId: "p2", name: "Book flight tickets", isCompleted: true, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-25), completedAt: Date().addingTimeInterval(-0.5)),
        ]
    }

    // MARK: - Computed Properties

    var completedTasks: [TodoTask] {
        tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    func activeTasks(for partitionId: String) -> [TodoTask] {
        tasks
            .filter { $0.partitionId == partitionId && !$0.isCompleted }
            .sorted { a, b in
                if a.isStarred && !b.isStarred { return true }
                if !a.isStarred && b.isStarred { return false }
                return a.createdAt > b.createdAt
            }
    }

    // MARK: - Task Actions

    func addTask(partitionId: String, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newTask = TodoTask(partitionId: partitionId, name: trimmed)
        tasks.insert(newTask, at: 0)
    }

    func toggleComplete(_ taskId: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
    }

    func toggleStar(_ taskId: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].isStarred.toggle()
    }

    func setDueDate(_ taskId: String, date: Date?) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].dueDate = date
    }

    func renameTask(_ taskId: String, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].name = trimmed
    }

    // MARK: - Partition Actions

    func addPartition() {
        let newPartition = Partition(name: "", color: .blue, height: 200)
        partitions.insert(newPartition, at: 0)
        editingPartitionId = newPartition.id
    }

    func savePartitionEdit(id: String, name: String, color: PartitionColor) {
        guard let index = partitions.firstIndex(where: { $0.id == id }) else { return }
        partitions[index].name = name.isEmpty ? "Untitled" : name
        partitions[index].color = color
        editingPartitionId = nil
    }

    func deletePartition(_ id: String) {
        partitions.removeAll { $0.id == id }
        tasks.removeAll { $0.partitionId == id }
    }

    func reorderPartitions(_ newPartitions: [Partition]) {
        partitions = newPartitions
    }

    func updatePartitionHeight(_ id: String, height: CGFloat) {
        guard let index = partitions.firstIndex(where: { $0.id == id }) else { return }
        partitions[index].height = max(80, height)
    }
}
