import XCTest
@testable import TodoApp

final class TodoViewModelV2Tests: XCTestCase {
    func testBracketSyntaxParsesNameAndTags() {
        let parsed = TodoTask.parseDisplayText("Write weekly review [work] [weekly]")

        XCTAssertEqual(parsed.name, "Write weekly review")
        XCTAssertEqual(parsed.tags, ["work", "weekly"])
        XCTAssertEqual(parsed.markupText, "Write weekly review [work] [weekly]")
    }

    func testBracketSyntaxPreservesDuplicateTags() {
        let parsed = TodoTask.parseDisplayText("Write weekly review [work] [work]")

        XCTAssertEqual(parsed.name, "Write weekly review")
        XCTAssertEqual(parsed.tags, ["work", "work"])
        XCTAssertEqual(parsed.markupText, "Write weekly review [work] [work]")
    }

    func testBracketSyntaxPreservesInlineTagPositionAfterSave() {
        let viewModel = makeViewModel()

        viewModel.updateTask(id: "root-work", rawText: "Write [focus] weekly review")

        XCTAssertEqual(viewModel.tasks.first(where: { $0.id == "root-work" })?.displayText, "Write [focus] weekly review")
    }

    func testRenderSegmentsCollapseWhitespaceAroundAdjacentTags() {
        let parsed = TodoTask.parseDisplayText("Plan [focus] [deep] session")
        let task = TodoTask(partitionId: "work", name: parsed.name, tags: parsed.tags, markupText: parsed.markupText)

        XCTAssertEqual(
            task.renderSegments,
            [
                .text("Plan"),
                .tag("focus"),
                .tag("deep"),
                .text("session")
            ]
        )
    }

    func testInlineTagTextGapMatchesSixPointSpacing() {
        XCTAssertEqual(DesignTokens.Spacing.inlineTagTextGap, 6)
    }

    func testPartitionTagHistoryRemainsScopedPerPartition() {
        let viewModel = makeViewModel()

        viewModel.updateRootTask(id: "root-work", name: "Work task", tags: ["alpha", "beta"])
        viewModel.addTask(partitionId: "life", name: "Life task", tags: ["groceries"])

        XCTAssertEqual(viewModel.tagHistory(for: "work"), ["alpha", "beta"])
        XCTAssertEqual(viewModel.tagHistory(for: "life"), ["groceries"])
    }

    func testChildTaskCanBeCreatedFromBracketSyntaxAndUpdatesHistory() throws {
        let viewModel = makeViewModel()

        viewModel.addChildTask(parentTaskId: "root-work", rawText: "Draft outline [focus]")

        let child = try XCTUnwrap(viewModel.tasks.first(where: { $0.parentTaskId == "root-work" }))
        XCTAssertEqual(child.tags, ["focus"])
        XCTAssertFalse(child.isStarred)
        XCTAssertTrue(viewModel.tagHistory(for: "work").contains("focus"))
    }

    func testAddingChildTaskKeepsParentPartitionAndRejectsGrandchildren() throws {
        let viewModel = makeViewModel()

        viewModel.addChildTask(parentTaskId: "root-work", name: "Draft outline")
        let child = try XCTUnwrap(viewModel.tasks.first(where: { $0.parentTaskId == "root-work" }))

        XCTAssertEqual(child.partitionId, "work")
        XCTAssertEqual(child.tags, [])

        viewModel.addChildTask(parentTaskId: child.id, name: "Should not exist")
        XCTAssertEqual(viewModel.tasks.filter { $0.parentTaskId == child.id }.count, 0)
    }

    func testChildStarOnlyChangesSiblingOrderAndNotRootOrder() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-older", partitionId: "work", name: "Older root", createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "root-newer", partitionId: "work", name: "Newer root", createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "child-a", partitionId: "work", name: "Child A", parentTaskId: "root-older", createdAt: Date(timeIntervalSince1970: 300)),
                TodoTask(id: "child-b", partitionId: "work", name: "Child B", parentTaskId: "root-older", createdAt: Date(timeIntervalSince1970: 400))
            ]
        )

        viewModel.toggleStar("child-a")

        let groups = viewModel.activeTaskGroups(for: "work")

        XCTAssertEqual(groups.map(\.rootTask.id), ["root-newer", "root-older"])
        XCTAssertEqual(groups.last?.children.map(\.id), ["child-a", "child-b"])
    }

    func testStarredRootTasksStayAtTopOfPartition() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-starred", partitionId: "work", name: "Starred root", isStarred: true, createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "root-newer", partitionId: "work", name: "Newer root", createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "root-oldest", partitionId: "work", name: "Oldest root", createdAt: Date(timeIntervalSince1970: 50))
            ]
        )

        XCTAssertEqual(viewModel.activeTaskGroups(for: "work").map(\.rootTask.id), ["root-starred", "root-newer", "root-oldest"])
    }

    func testRestarringRootMovesItToTopOfStarredRoots() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-a", partitionId: "work", name: "Root A", isStarred: true, createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "root-b", partitionId: "work", name: "Root B", isStarred: true, createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "root-c", partitionId: "work", name: "Root C", createdAt: Date(timeIntervalSince1970: 300))
            ]
        )

        viewModel.toggleStar("root-a")
        viewModel.toggleStar("root-a")

        XCTAssertEqual(viewModel.activeTaskGroups(for: "work").map(\.rootTask.id), ["root-a", "root-b", "root-c"])
    }

    func testNewChildTaskAppearsBelowStarredChildrenAndAboveOtherRegularChildren() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent", createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "child-starred", partitionId: "work", name: "Starred child", parentTaskId: "root-work", isStarred: true, createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "child-regular", partitionId: "work", name: "Regular child", parentTaskId: "root-work", createdAt: Date(timeIntervalSince1970: 300))
            ]
        )

        viewModel.addChildTask(parentTaskId: "root-work", name: "Newest child")

        XCTAssertEqual(
            viewModel.activeTaskGroups(for: "work").first?.children.map(\.name),
            ["Starred child", "Newest child", "Regular child"]
        )
    }

    func testUnstarringChildMovesItToTopOfRegularChildrenWhenNoOtherStarredTasksExist() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent", createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "child-a", partitionId: "work", name: "Older child", parentTaskId: "root-work", createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "child-b", partitionId: "work", name: "Newer child", parentTaskId: "root-work", createdAt: Date(timeIntervalSince1970: 300))
            ]
        )

        viewModel.toggleStar("child-a")
        viewModel.toggleStar("child-a")

        XCTAssertEqual(viewModel.activeTaskGroups(for: "work").first?.children.map(\.id), ["child-a", "child-b"])
    }

    func testUnstarringChildMovesItToTopOfRegularChildren() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent", createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "child-star-a", partitionId: "work", name: "Star A", parentTaskId: "root-work", isStarred: true, createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "child-star-b", partitionId: "work", name: "Star B", parentTaskId: "root-work", isStarred: true, createdAt: Date(timeIntervalSince1970: 300)),
                TodoTask(id: "child-regular-a", partitionId: "work", name: "Regular A", parentTaskId: "root-work", createdAt: Date(timeIntervalSince1970: 400)),
                TodoTask(id: "child-regular-b", partitionId: "work", name: "Regular B", parentTaskId: "root-work", createdAt: Date(timeIntervalSince1970: 500))
            ]
        )

        viewModel.toggleStar("child-star-a")

        XCTAssertEqual(
            viewModel.activeTaskGroups(for: "work").first?.children.map(\.id),
            ["child-star-b", "child-star-a", "child-regular-b", "child-regular-a"]
        )
    }

    func testUnstarringRootMovesItToTopOfRegularRoots() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-star-a", partitionId: "work", name: "Star A", isStarred: true, createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "root-star-b", partitionId: "work", name: "Star B", isStarred: true, createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "root-regular-a", partitionId: "work", name: "Regular A", createdAt: Date(timeIntervalSince1970: 300)),
                TodoTask(id: "root-regular-b", partitionId: "work", name: "Regular B", createdAt: Date(timeIntervalSince1970: 400))
            ]
        )

        viewModel.toggleStar("root-star-a")

        XCTAssertEqual(
            viewModel.activeTaskGroups(for: "work").map(\.rootTask.id),
            ["root-star-b", "root-star-a", "root-regular-b", "root-regular-a"]
        )
    }

    func testRestarringChildMovesItToTopOfStarredChildren() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent", createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "child-a", partitionId: "work", name: "Child A", parentTaskId: "root-work", isStarred: true, createdAt: Date(timeIntervalSince1970: 200)),
                TodoTask(id: "child-b", partitionId: "work", name: "Child B", parentTaskId: "root-work", isStarred: true, createdAt: Date(timeIntervalSince1970: 300))
            ]
        )

        viewModel.toggleStar("child-a")
        viewModel.toggleStar("child-a")

        XCTAssertEqual(viewModel.activeTaskGroups(for: "work").first?.children.map(\.id), ["child-a", "child-b"])
    }

    func testCompletedChildShowsParentContextWhileParentStaysActive() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent", createdAt: Date(timeIntervalSince1970: 100)),
                TodoTask(id: "child-a", partitionId: "work", name: "Child A", parentTaskId: "root-work", createdAt: Date(timeIntervalSince1970: 200))
            ]
        )

        viewModel.toggleComplete("child-a")

        let activeGroups = viewModel.activeTaskGroups(for: "work")
        let completedGroups = viewModel.completedTaskGroups

        XCTAssertEqual(activeGroups.count, 1)
        XCTAssertEqual(activeGroups[0].rootTask.id, "root-work")
        XCTAssertFalse(activeGroups[0].rootTask.isCompleted)

        XCTAssertEqual(completedGroups.count, 1)
        XCTAssertEqual(completedGroups[0].rootTask.id, "root-work")
        XCTAssertTrue(completedGroups[0].showsParentContext)
        XCTAssertFalse(completedGroups[0].allowsRootCompletionToggle)
        XCTAssertEqual(completedGroups[0].completedChildren.map(\.id), ["child-a"])
    }

    func testCompletedRootStillAllowsCompletionToggle() {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(
                    id: "root-work",
                    partitionId: "work",
                    name: "Parent",
                    isCompleted: true,
                    completedAt: Date(timeIntervalSince1970: 300)
                )
            ]
        )

        let completedGroups = viewModel.completedTaskGroups

        XCTAssertEqual(completedGroups.count, 1)
        XCTAssertFalse(completedGroups[0].showsParentContext)
        XCTAssertTrue(completedGroups[0].allowsRootCompletionToggle)
    }

    func testParentDoesNotAutoCompleteWhenAllChildrenAreCompleted() throws {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent"),
                TodoTask(id: "child-a", partitionId: "work", name: "Child A", parentTaskId: "root-work"),
                TodoTask(id: "child-b", partitionId: "work", name: "Child B", parentTaskId: "root-work")
            ]
        )

        viewModel.toggleComplete("child-a")
        viewModel.toggleComplete("child-b")

        let parent = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "root-work" }))
        XCTAssertFalse(parent.isCompleted)
        XCTAssertEqual(viewModel.completedTaskGroups.first?.completedChildren.count, 2)
        XCTAssertTrue(viewModel.completedTaskGroups.first?.showsParentContext ?? false)
    }

    func testCompletingParentCascadesToIncompleteChildren() throws {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(id: "root-work", partitionId: "work", name: "Parent"),
                TodoTask(id: "child-a", partitionId: "work", name: "Child A", parentTaskId: "root-work"),
                TodoTask(id: "child-b", partitionId: "work", name: "Child B", parentTaskId: "root-work", isCompleted: true, completedAt: Date(timeIntervalSince1970: 50))
            ]
        )

        viewModel.toggleComplete("root-work")

        let parent = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "root-work" }))
        let childA = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "child-a" }))
        let childB = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "child-b" }))

        XCTAssertTrue(parent.isCompleted)
        XCTAssertTrue(childA.isCompleted)
        XCTAssertTrue(childB.isCompleted)
        XCTAssertEqual(viewModel.activeTaskGroups(for: "work").count, 0)
        XCTAssertEqual(viewModel.completedTaskGroups.first?.rootTask.id, "root-work")
        XCTAssertFalse(viewModel.completedTaskGroups.first?.showsParentContext ?? true)
        XCTAssertEqual(Set(viewModel.completedTaskGroups.first?.completedChildren.map(\.id) ?? []), Set(["child-a", "child-b"]))
    }

    func testUncompletingChildFromCompletedRootReturnsParentAndChildToActiveSection() throws {
        let viewModel = makeViewModel(
            tasks: [
                TodoTask(
                    id: "root-work",
                    partitionId: "work",
                    name: "Parent",
                    isCompleted: true,
                    completedAt: Date(timeIntervalSince1970: 400)
                ),
                TodoTask(
                    id: "child-a",
                    partitionId: "work",
                    name: "Child A",
                    parentTaskId: "root-work",
                    isCompleted: true,
                    completedAt: Date(timeIntervalSince1970: 300)
                ),
                TodoTask(
                    id: "child-b",
                    partitionId: "work",
                    name: "Child B",
                    parentTaskId: "root-work",
                    isCompleted: true,
                    completedAt: Date(timeIntervalSince1970: 200)
                )
            ]
        )

        viewModel.toggleComplete("child-a")

        let parent = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "root-work" }))
        let childA = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "child-a" }))
        let childB = try XCTUnwrap(viewModel.tasks.first(where: { $0.id == "child-b" }))

        XCTAssertFalse(parent.isCompleted)
        XCTAssertNil(parent.completedAt)
        XCTAssertFalse(childA.isCompleted)
        XCTAssertNil(childA.completedAt)
        XCTAssertTrue(childB.isCompleted)

        let activeGroups = viewModel.activeTaskGroups(for: "work")
        XCTAssertEqual(activeGroups.map(\.rootTask.id), ["root-work"])
        XCTAssertEqual(activeGroups.first?.children.map(\.id), ["child-a"])

        let completedGroups = viewModel.completedTaskGroups
        XCTAssertEqual(completedGroups.count, 1)
        XCTAssertTrue(completedGroups[0].showsParentContext)
        XCTAssertEqual(completedGroups[0].completedChildren.map(\.id), ["child-b"])
    }

    private func makeViewModel(tasks: [TodoTask]? = nil) -> TodoViewModel {
        TodoViewModel(
            partitions: [
                Partition(id: "work", name: "Work", color: .blue, height: 200),
                Partition(id: "life", name: "Life", color: .green, height: 200)
            ],
            tasks: tasks ?? [
                TodoTask(id: "root-work", partitionId: "work", name: "Work root", tags: ["alpha"]),
                TodoTask(id: "root-life", partitionId: "life", name: "Life root")
            ]
        )
    }
}
