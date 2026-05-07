import XCTest
@testable import TodoApp

final class DueDateLabelLayoutTests: XCTestCase {
    func testAllDueDateStylesShareTheSameRightAlignedTextFrame() {
        XCTAssertEqual(
            DueDateLabelLayout.textWidth,
            DesignTokens.Size.dueDateTextContentWidth
        )
        XCTAssertEqual(
            DueDateLabelLayout.labelWidth,
            DueDateLabelLayout.textWidth + (DesignTokens.Spacing.dueDateTagHorizontal * 2)
        )
    }

    func testDueDateTextTrailingEdgeUsesSharedInsetForEveryStyle() {
        XCTAssertEqual(
            DueDateLabelLayout.textTrailingInset,
            DesignTokens.Spacing.dueDateTagHorizontal
        )
    }

    func testShortDueDateTagsKeepIntrinsicWidthInsideRightAlignedSlot() {
        XCTAssertLessThan(
            DueDateLabelLayout.tagWidth(for: "Due Today"),
            DueDateLabelLayout.labelWidth
        )
    }
}
