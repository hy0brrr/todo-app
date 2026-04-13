import Foundation

enum ChildTaskRow: Identifiable, Equatable {
    case child(TodoTask)
    case inlineDraft(parentTaskId: String)

    var id: String {
        switch self {
        case .child(let task):
            return "child-\(task.id)"
        case .inlineDraft(let parentTaskId):
            return "draft-\(parentTaskId)"
        }
    }
}

enum ChildTaskOrdering {
    static func inlineDraftInsertionIndex(for children: [TodoTask]) -> Int {
        children.prefix { $0.isStarred }.count
    }

    static func orderedRows(
        for children: [TodoTask],
        parentTaskId: String,
        showInlineDraft: Bool
    ) -> [ChildTaskRow] {
        let insertionIndex = inlineDraftInsertionIndex(for: children)
        let childRows = children.map(ChildTaskRow.child)

        guard showInlineDraft else { return childRows }

        var rows = childRows
        rows.insert(.inlineDraft(parentTaskId: parentTaskId), at: insertionIndex)
        return rows
    }
}
