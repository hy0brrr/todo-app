import Foundation
import SwiftUI
import AppKit

enum AppFontWeightRole {
    case regular
    case medium
    case semibold
    case bold
    case heavy
}

enum AppFontPreviewOption: String, CaseIterable, Identifiable {
    case pingFang
    case sourceHanSans
    case sourceHanSerif
    case founderLantinghei
    case founderYouhei

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pingFang:
            return "苹方"
        case .sourceHanSans:
            return "思源黑体"
        case .sourceHanSerif:
            return "思源宋体"
        case .founderLantinghei:
            return "方正兰亭黑"
        case .founderYouhei:
            return "方正悠黑"
        }
    }

    var sampleText: String {
        switch self {
        case .pingFang:
            return "清爽原生"
        case .sourceHanSans:
            return "现代中性"
        case .sourceHanSerif:
            return "书卷层次"
        case .founderLantinghei:
            return "锋利克制"
        case .founderYouhei:
            return "尚未安装"
        }
    }

    var availabilityText: String {
        isInstalled ? "已安装" : "未安装"
    }

    var isInstalled: Bool {
        fontName(for: .regular).map { NSFont(name: $0, size: 16) != nil } ?? false
    }

    func fontName(for role: AppFontWeightRole) -> String? {
        switch self {
        case .pingFang:
            switch role {
            case .regular:
                return "PingFangSC-Regular"
            case .medium:
                return "PingFangSC-Medium"
            case .semibold, .bold, .heavy:
                return "PingFangSC-Semibold"
            }
        case .sourceHanSans:
            switch role {
            case .regular:
                return "SourceHanSansCN-Regular"
            case .medium, .semibold:
                return "SourceHanSansCN-Medium"
            case .bold:
                return "SourceHanSansCN-Bold"
            case .heavy:
                return "SourceHanSansCN-Heavy"
            }
        case .sourceHanSerif:
            switch role {
            case .regular:
                return "SourceHanSerifSC-Regular"
            case .medium:
                return "SourceHanSerifSC-Medium"
            case .semibold:
                return "SourceHanSerifSC-SemiBold"
            case .bold:
                return "SourceHanSerifSC-Bold"
            case .heavy:
                return "SourceHanSerifSC-Heavy"
            }
        case .founderLantinghei:
            switch role {
            case .regular:
                return "FZLTXHK--GBK1-0"
            case .medium, .semibold, .bold:
                return "FZLTZHK--GBK1-0"
            case .heavy:
                return "FZLTTHK--GBK1-0"
            }
        case .founderYouhei:
            switch role {
            case .regular:
                return "FZYouHeiS-R-GB"
            case .medium, .semibold:
                return "FZYouHei-M08S"
            case .bold, .heavy:
                return "FZYouHei-M08S"
            }
        }
    }

    func swiftUIFont(size: CGFloat, role: AppFontWeightRole, fallbackWeight: Font.Weight, design: Font.Design = .rounded) -> Font {
        if let fontName = fontName(for: role), NSFont(name: fontName, size: size) != nil {
            return .custom(fontName, size: size)
        }

        return .system(size: size, weight: fallbackWeight, design: design)
    }
}

@Observable
class TodoViewModel {
    var partitions: [Partition]
    var tasks: [TodoTask]
    var editingPartitionId: String? = nil
    var showManagePartitions: Bool = false
    var sidebarWidth: CGFloat = 320
    var selectedFontOption: AppFontPreviewOption = .pingFang {
        didSet {
            DesignTokens.Typography.previewOption = selectedFontOption
        }
    }

    init() {
        let today = Calendar.current.startOfDay(for: Date())

        self.partitions = [
            Partition(id: "p1", name: "工作", color: .blue, height: 200),
            Partition(id: "p2", name: "生活", color: .green, height: 200),
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

        DesignTokens.Typography.previewOption = selectedFontOption
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
