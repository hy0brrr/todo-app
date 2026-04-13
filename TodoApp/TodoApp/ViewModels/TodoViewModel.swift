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

struct ActiveTaskGroup: Identifiable, Equatable {
    let rootTask: TodoTask
    let children: [TodoTask]

    var id: String { rootTask.id }
}

struct CompletedTaskGroup: Identifiable, Equatable {
    let rootTask: TodoTask
    let completedChildren: [TodoTask]
    let showsParentContext: Bool

    var id: String { rootTask.id }
    var allowsRootCompletionToggle: Bool { !showsParentContext }

    var latestCompletionDate: Date {
        let childLatest = completedChildren
            .compactMap(\.completedAt)
            .max() ?? .distantPast

        if showsParentContext {
            return childLatest
        }

        return max(rootTask.completedAt ?? .distantPast, childLatest)
    }
}

@Observable
class TodoViewModel {
    var partitions: [Partition]
    var tasks: [TodoTask]
    var tagHistoryByPartition: [String: [String]]
    var editingPartitionId: String? = nil
    var showManagePartitions: Bool = false
    var sidebarWidth: CGFloat = 320

    init(
        partitions: [Partition],
        tasks: [TodoTask],
        tagHistoryByPartition: [String: [String]]? = nil
    ) {
        TitleFontRegistrar.registerLocalPreviewFonts()
        self.partitions = partitions
        self.tasks = tasks
        self.tagHistoryByPartition = TodoViewModel.buildTagHistory(
            tasks: tasks,
            seed: tagHistoryByPartition ?? [:]
        )
    }

    convenience init() {
        let today = Calendar.current.startOfDay(for: Date())

        self.init(
            partitions: [
                Partition(id: "p1", name: "Work", color: .blue, height: 200),
                Partition(id: "p2", name: "Life", color: .green, height: 200),
            ],
            tasks: [
                TodoTask(id: "t1", partitionId: "p1", name: "整理第二季度产品需求", tags: ["Strategy", "Q2"], isStarred: true, createdAt: Date().addingTimeInterval(-10)),
                TodoTask(id: "t1-1", partitionId: "p1", name: "补齐竞品调研", parentTaskId: "t1", isStarred: true, createdAt: Date().addingTimeInterval(-9)),
                TodoTask(id: "t1-2", partitionId: "p1", name: "汇总访谈笔记", parentTaskId: "t1", createdAt: Date().addingTimeInterval(-8)),
                TodoTask(id: "t2", partitionId: "p1", name: "更新路线图", tags: ["Planning"], dueDate: today, createdAt: Date().addingTimeInterval(-5)),
                TodoTask(id: "t3", partitionId: "p1", name: "和设计同步细节", tags: ["Design"], createdAt: Date().addingTimeInterval(-2)),
                TodoTask(id: "t4", partitionId: "p2", name: "采购今晚食材", tags: ["Errands", "Home"], isStarred: true, createdAt: Date().addingTimeInterval(-8)),
                TodoTask(id: "t4-1", partitionId: "p2", name: "列一份购物清单", parentTaskId: "t4", createdAt: Date().addingTimeInterval(-7)),
                TodoTask(id: "t5", partitionId: "p2", name: "去拿洗好的衣服", tags: ["Errands"], createdAt: Date().addingTimeInterval(-4)),
                TodoTask(id: "t6", partitionId: "p1", name: "写周报", tags: ["Weekly"], isCompleted: true, createdAt: Date().addingTimeInterval(-20), completedAt: Date().addingTimeInterval(-1)),
                TodoTask(id: "t7", partitionId: "p2", name: "预订机票", tags: ["Travel"], isCompleted: true, createdAt: Date().addingTimeInterval(-25), completedAt: Date().addingTimeInterval(-0.5)),
            ]
        )
    }

    // MARK: - Computed Properties

    var completedTaskGroups: [CompletedTaskGroup] {
        rootTasks
            .compactMap { root in
                let completedChildren = children(of: root.id)
                    .filter(\.isCompleted)
                    .sorted(by: completedTaskSort)

                if root.isCompleted {
                    return CompletedTaskGroup(
                        rootTask: root,
                        completedChildren: completedChildren,
                        showsParentContext: false
                    )
                }

                guard !completedChildren.isEmpty else { return nil }
                return CompletedTaskGroup(
                    rootTask: root,
                    completedChildren: completedChildren,
                    showsParentContext: true
                )
            }
            .sorted { $0.latestCompletionDate > $1.latestCompletionDate }
    }

    var completedTasks: [TodoTask] {
        completedTaskGroups.flatMap { group in
            if group.showsParentContext {
                return group.completedChildren
            }
            return [group.rootTask] + group.completedChildren
        }
    }

    func activeTaskGroups(for partitionId: String) -> [ActiveTaskGroup] {
        rootTasks
            .filter { $0.partitionId == partitionId && !$0.isCompleted }
            .sorted(by: activeTaskSort)
            .map { root in
                ActiveTaskGroup(
                    rootTask: root,
                    children: children(of: root.id)
                        .filter { !$0.isCompleted }
                        .sorted(by: activeTaskSort)
                )
            }
    }

    func activeTasks(for partitionId: String) -> [TodoTask] {
        activeTaskGroups(for: partitionId)
            .flatMap { [$0.rootTask] + $0.children }
    }

    // MARK: - Task Actions

    func addTask(partitionId: String, name: String, tags: [String] = []) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let normalizedTags = normalizeTags(tags)
        let newTask = TodoTask(
            partitionId: partitionId,
            name: trimmed,
            tags: normalizedTags
        )
        tasks.insert(newTask, at: 0)
        rememberTags(normalizedTags, for: partitionId)
    }

    func addTask(partitionId: String, rawText: String) {
        let parsed = TodoTask.parseDisplayText(rawText)
        guard !parsed.name.isEmpty else { return }
        let newTask = TodoTask(
            partitionId: partitionId,
            name: parsed.name,
            tags: parsed.tags,
            markupText: parsed.markupText
        )
        tasks.insert(newTask, at: 0)
        rememberTags(parsed.tags, for: partitionId)
    }

    func addChildTask(parentTaskId: String, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let parent = task(withId: parentTaskId), parent.isRootTask else { return }

        let childTask = TodoTask(
            partitionId: parent.partitionId,
            name: trimmed,
            parentTaskId: parentTaskId
        )
        tasks.insert(childTask, at: 0)
    }

    func addChildTask(parentTaskId: String, rawText: String) {
        let parsed = TodoTask.parseDisplayText(rawText)
        guard !parsed.name.isEmpty else { return }
        guard let parent = task(withId: parentTaskId), parent.isRootTask else { return }

        let childTask = TodoTask(
            partitionId: parent.partitionId,
            name: parsed.name,
            parentTaskId: parentTaskId,
            tags: parsed.tags,
            markupText: parsed.markupText
        )
        tasks.insert(childTask, at: 0)
        rememberTags(parsed.tags, for: parent.partitionId)
    }

    func toggleComplete(_ taskId: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let timestamp = Date()

        if tasks[index].isRootTask {
            if tasks[index].isCompleted {
                tasks[index].isCompleted = false
                tasks[index].completedAt = nil
                for childIndex in childIndices(of: taskId) {
                    tasks[childIndex].isCompleted = false
                    tasks[childIndex].completedAt = nil
                }
                return
            }

            tasks[index].isCompleted = true
            tasks[index].completedAt = timestamp

            for childIndex in childIndices(of: taskId) where !tasks[childIndex].isCompleted {
                tasks[childIndex].isCompleted = true
                tasks[childIndex].completedAt = timestamp
            }
            return
        }

        if tasks[index].isCompleted {
            tasks[index].isCompleted = false
            tasks[index].completedAt = nil

            if let parentTaskId = tasks[index].parentTaskId,
               let parentIndex = tasks.firstIndex(where: { $0.id == parentTaskId }),
               tasks[parentIndex].isCompleted {
                tasks[parentIndex].isCompleted = false
                tasks[parentIndex].completedAt = nil
            }
            return
        }

        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = timestamp
    }

    func toggleStar(_ taskId: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].isStarred.toggle()
        let timestamp = Date()
        tasks[index].starredAt = tasks[index].isStarred ? timestamp : nil
        tasks[index].unstarredAt = tasks[index].isStarred ? nil : timestamp
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

    func updateTask(id: String, name: String, tags: [String]) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        let normalizedTags = normalizeTags(tags)
        tasks[index].name = trimmed
        tasks[index].tags = normalizedTags
        tasks[index].markupText = TodoTask(
            partitionId: tasks[index].partitionId,
            name: trimmed,
            parentTaskId: tasks[index].parentTaskId,
            tags: normalizedTags
        ).markupText
        rememberTags(normalizedTags, for: tasks[index].partitionId)
    }

    func updateTask(id: String, rawText: String) {
        let parsed = TodoTask.parseDisplayText(rawText)
        guard !parsed.name.isEmpty else { return }
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].name = parsed.name
        tasks[index].tags = parsed.tags
        tasks[index].markupText = parsed.markupText
        rememberTags(parsed.tags, for: tasks[index].partitionId)
    }

    func updateRootTask(id: String, name: String, tags: [String]) {
        updateTask(id: id, name: name, tags: tags)
    }

    func tagHistory(for partitionId: String) -> [String] {
        tagHistoryByPartition[partitionId] ?? []
    }

    // MARK: - Partition Actions

    func addPartition() {
        let newPartition = Partition(name: "", color: .blue, height: 200)
        partitions.insert(newPartition, at: 0)
        editingPartitionId = newPartition.id
    }

    func savePartitionEdit(id: String, name: String) {
        guard let index = partitions.firstIndex(where: { $0.id == id }) else { return }
        partitions[index].name = name.isEmpty ? "Untitled" : name
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

    // MARK: - Helpers

    private var rootTasks: [TodoTask] {
        tasks.filter(\.isRootTask)
    }

    private func task(withId id: String) -> TodoTask? {
        tasks.first(where: { $0.id == id })
    }

    private func children(of rootTaskId: String) -> [TodoTask] {
        tasks.filter { $0.parentTaskId == rootTaskId }
    }

    private func childIndices(of rootTaskId: String) -> [Int] {
        tasks.indices.filter { tasks[$0].parentTaskId == rootTaskId }
    }

    private func rememberTags(_ tags: [String], for partitionId: String) {
        guard !tags.isEmpty else { return }

        var history = tagHistoryByPartition[partitionId] ?? []
        for tag in tags where !history.contains(tag) {
            history.append(tag)
        }
        tagHistoryByPartition[partitionId] = history
    }

    private func normalizeTags(_ tags: [String]) -> [String] {
        TodoTask.normalizeTags(tags)
    }

    private func activeTaskSort(_ lhs: TodoTask, _ rhs: TodoTask) -> Bool {
        if lhs.isStarred && !rhs.isStarred { return true }
        if !lhs.isStarred && rhs.isStarred { return false }
        if lhs.isStarred && rhs.isStarred {
            return (lhs.starredAt ?? lhs.createdAt) > (rhs.starredAt ?? rhs.createdAt)
        }
        return (lhs.unstarredAt ?? lhs.createdAt) > (rhs.unstarredAt ?? rhs.createdAt)
    }

    private func completedTaskSort(_ lhs: TodoTask, _ rhs: TodoTask) -> Bool {
        (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
    }

    private static func buildTagHistory(
        tasks: [TodoTask],
        seed: [String: [String]]
    ) -> [String: [String]] {
        var history = seed

        for task in tasks {
            var partitionHistory = history[task.partitionId] ?? []
            for tag in task.tags where !partitionHistory.contains(tag) {
                partitionHistory.append(tag)
            }
            history[task.partitionId] = partitionHistory
        }

        return history
    }
}
