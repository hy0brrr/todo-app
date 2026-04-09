import Foundation
import SwiftUI
import AppKit
import CoreText

enum AppFontWeightRole {
    case regular
    case medium
    case semibold
    case bold
    case heavy
}

enum TitleFontRegistrar {
    private static var hasRegistered = false

    private static let localPreviewFontFiles = [
        "neue-montreal.ttf",
    ]

    static func registerLocalPreviewFonts() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Fonts/TitlePreview", isDirectory: true)

        for fileName in localPreviewFontFiles {
            let url = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}

@Observable
class TodoViewModel {
    var partitions: [Partition]
    var tasks: [TodoTask]
    var editingPartitionId: String? = nil
    var showManagePartitions: Bool = false
    var sidebarWidth: CGFloat = 320

    init() {
        TitleFontRegistrar.registerLocalPreviewFonts()
        let today = Calendar.current.startOfDay(for: Date())

        self.partitions = [
            Partition(id: "p1", name: "Work", color: .blue, height: 200),
            Partition(id: "p2", name: "Life", color: .green, height: 200),
        ]

        self.tasks = [
            TodoTask(id: "t1", partitionId: "p1", name: "整理第二季度产品需求", isCompleted: false, isStarred: true, dueDate: nil, createdAt: Date().addingTimeInterval(-10)),
            TodoTask(id: "t2", partitionId: "p1", name: "更新路线图", isCompleted: false, isStarred: false, dueDate: today, createdAt: Date().addingTimeInterval(-5)),
            TodoTask(id: "t3", partitionId: "p1", name: "和设计同步细节", isCompleted: false, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-2)),
            TodoTask(id: "t4", partitionId: "p2", name: "采购今晚食材", isCompleted: false, isStarred: true, dueDate: nil, createdAt: Date().addingTimeInterval(-8)),
            TodoTask(id: "t5", partitionId: "p2", name: "去拿洗好的衣服", isCompleted: false, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-4)),
            TodoTask(id: "t6", partitionId: "p1", name: "写周报", isCompleted: true, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-20), completedAt: Date().addingTimeInterval(-1)),
            TodoTask(id: "t7", partitionId: "p2", name: "预订机票", isCompleted: true, isStarred: false, dueDate: nil, createdAt: Date().addingTimeInterval(-25), completedAt: Date().addingTimeInterval(-0.5)),
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
        partitions[index].height = max(DesignTokens.Size.partitionMinHeight, height)
    }

    func adjustPartitionHeight(_ id: String, delta: CGFloat) {
        guard let index = partitions.firstIndex(where: { $0.id == id }) else { return }
        partitions[index].height = max(
            DesignTokens.Size.partitionMinHeight,
            partitions[index].height + delta
        )
    }

    func resizeBoundary(
        after id: String,
        delta: CGFloat,
        maxTotalPartitionHeights: CGFloat
    ) {
        guard let index = partitions.firstIndex(where: { $0.id == id }) else { return }
        let minHeight = DesignTokens.Size.partitionMinHeight

        if index < partitions.count - 1 {
            let currentHeight = partitions[index].height
            let nextHeight = partitions[index + 1].height
            let maxShrinkCurrent = currentHeight - minHeight

            if delta < 0 {
                let clampedDelta = max(delta, -maxShrinkCurrent)
                partitions[index].height = currentHeight + clampedDelta
                partitions[index + 1].height = nextHeight - clampedDelta
                return
            }

            let nextShrinkBudget = max(0, nextHeight - minHeight)
            let totalHeights = partitions.reduce(CGFloat.zero) { partialResult, partition in
                partialResult + partition.height
            }
            let completedShrinkBudget = max(0, maxTotalPartitionHeights - totalHeights)
            let allowedGrowth = nextShrinkBudget + completedShrinkBudget
            let clampedDelta = min(delta, allowedGrowth)
            let consumedFromNext = min(clampedDelta, nextShrinkBudget)

            partitions[index].height = currentHeight + clampedDelta
            partitions[index + 1].height = nextHeight - consumedFromNext
            return
        }

        let currentHeight = partitions[index].height
        let totalHeights = partitions.reduce(CGFloat.zero) { partialResult, partition in
            partialResult + partition.height
        }
        let remainingGrowBudget = max(0, maxTotalPartitionHeights - totalHeights)
        let maxShrink = currentHeight - minHeight
        let clampedDelta = min(max(delta, -maxShrink), remainingGrowBudget)

        partitions[index].height = currentHeight + clampedDelta
    }
}
