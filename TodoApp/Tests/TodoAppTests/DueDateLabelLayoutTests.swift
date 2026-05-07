import XCTest
@testable import TodoApp

final class DueDateLabelLayoutTests: XCTestCase {
    func testDueDateTextTrailingEdgeUsesSharedInsetForEveryStyle() {
        XCTAssertEqual(
            DueDateLabelLayout.textTrailingInset,
            DesignTokens.Spacing.dueDateTagHorizontal
        )
    }

    func testShortDueDateTagsKeepIntrinsicWidthInsideRightAlignedSlot() {
        XCTAssertLessThan(
            DueDateLabelLayout.tagWidth(for: "Due Today"),
            DueDateLabelLayout.tagWidth(for: "Due Tomorrow")
        )
    }

    func testRowsWithoutDueDateReserveOnlyCalendarControlWidth() {
        XCTAssertEqual(
            TaskRowTrailingLayout.reservedWidth(hasDueDate: false, dueDateContentWidth: 999),
            TaskRowTrailingLayout.reservedWidth(hasDueDate: false, dueDateContentWidth: 0)
        )
    }

    func testRowsWithDueDateKeepTwelvePointGapFromTaskTextToDueDateContent() {
        XCTAssertEqual(
            TaskRowTrailingLayout.contentGap(hasDueDate: true),
            12
        )
    }

    func testRowsWithoutDueDateKeepFourPointGapFromTaskTextToCalendarIcon() {
        XCTAssertEqual(
            TaskRowTrailingLayout.contentGap(hasDueDate: false),
            4
        )
    }

    func testRowsWithDueDateReserveOnlyCurrentDueDateContentWidth() {
        XCTAssertLessThan(
            TaskRowTrailingLayout.reservedWidth(
                hasDueDate: true,
                dueDateContentWidth: DueDateLabelLayout.tagWidth(for: "Due Today")
            ),
            TaskRowTrailingLayout.reservedWidth(
                hasDueDate: true,
                dueDateContentWidth: DueDateLabelLayout.tagWidth(for: "Due Tomorrow")
            )
        )
    }
}
