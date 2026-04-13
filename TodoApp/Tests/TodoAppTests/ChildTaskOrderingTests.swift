import XCTest
@testable import TodoApp

final class ChildTaskOrderingTests: XCTestCase {
    func testInlineDraftIsInsertedAfterStarredChildren() {
        let children = [
            TodoTask(id: "child-starred", partitionId: "work", name: "Starred", parentTaskId: "root", isStarred: true),
            TodoTask(id: "child-plain-a", partitionId: "work", name: "Plain A", parentTaskId: "root"),
            TodoTask(id: "child-plain-b", partitionId: "work", name: "Plain B", parentTaskId: "root")
        ]

        XCTAssertEqual(ChildTaskOrdering.inlineDraftInsertionIndex(for: children), 1)
    }

    func testOrderedRowsKeepDraftAndChildrenInSingleSequence() {
        let children = [
            TodoTask(id: "child-starred", partitionId: "work", name: "Starred", parentTaskId: "root", isStarred: true),
            TodoTask(id: "child-plain-a", partitionId: "work", name: "Plain A", parentTaskId: "root"),
            TodoTask(id: "child-plain-b", partitionId: "work", name: "Plain B", parentTaskId: "root")
        ]

        let rows = ChildTaskOrdering.orderedRows(
            for: children,
            parentTaskId: "root",
            showInlineDraft: true
        )

        XCTAssertEqual(
            rows.map(\.id),
            ["child-child-starred", "draft-root", "child-child-plain-a", "child-child-plain-b"]
        )
    }
}
