import XCTest
@testable import TodoApp

final class StarMarkerPresentationTests: XCTestCase {
    func testCompletedRowsDoNotShowHoverPreviewForUnstarredTasks() {
        XCTAssertFalse(
            StarMarkerPresentation.showsMarker(
                taskIsStarred: false,
                renderMode: .completed,
                isHoveringRow: true,
                isHoveringMarker: true
            )
        )
    }

    func testCompletedRowsKeepMarkerForStarredTasks() {
        XCTAssertTrue(
            StarMarkerPresentation.showsMarker(
                taskIsStarred: true,
                renderMode: .completed,
                isHoveringRow: false,
                isHoveringMarker: false
            )
        )
    }

    func testCompletedRowsDisableStarInteraction() {
        XCTAssertFalse(StarMarkerPresentation.allowsInteraction(renderMode: .completed))
        XCTAssertTrue(StarMarkerPresentation.allowsInteraction(renderMode: .active))
    }

    func testStarMarkerUsesPointingHandCursor() {
        XCTAssertTrue(TodoCursors.starMarkerAction === NSCursor.pointingHand)
    }

    func testVisibleStarMarkerStaysInsideTapTarget() {
        let markerLeadingEdge = DesignTokens.Spacing.starMarkerLeadingOffset
        let markerTrailingEdge = markerLeadingEdge + DesignTokens.Size.starMarkerWidth

        XCTAssertGreaterThanOrEqual(markerLeadingEdge, 0)
        XCTAssertLessThanOrEqual(markerTrailingEdge, DesignTokens.Size.starMarkerTapTargetWidth)
    }

    func testStarMarkerTapTargetIsWiderThanTheTinyVisualMarker() {
        XCTAssertGreaterThanOrEqual(DesignTokens.Size.starMarkerTapTargetWidth, 16)
    }

    func testStarMarkerTapTargetIncludesLeadingSpaceBeforeVisibleMarker() {
        XCTAssertGreaterThanOrEqual(DesignTokens.Spacing.starMarkerLeadingOffset, 8)
    }

    func testChildStarMarkerHitRegionFollowsChildIndent() {
        let parentHitLeading = TaskItemLeadingControlLayout.starMarkerHitRegionLeadingInset(depth: 0)
        let childHitLeading = TaskItemLeadingControlLayout.starMarkerHitRegionLeadingInset(depth: 1)

        XCTAssertEqual(
            childHitLeading - parentHitLeading,
            DesignTokens.Spacing.childTaskIndent
        )
    }

    func testStarMarkerHitRegionEndsWhereCheckboxHitRegionBegins() {
        let checkboxHitLeading = DesignTokens.Spacing.rowHorizontal
            + TaskItemLeadingControlLayout.checkboxLeadingInset()
        let starHitLeading = TaskItemLeadingControlLayout.starMarkerHitRegionLeadingInset(depth: 0)

        XCTAssertEqual(
            starHitLeading + DesignTokens.Size.starMarkerTapTargetWidth,
            checkboxHitLeading
        )
    }
}
