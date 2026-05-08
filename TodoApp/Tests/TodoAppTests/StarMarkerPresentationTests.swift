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

    func testUnstarredRootHoverMarkerUsesDarkPreviewFill() {
        XCTAssertEqual(
            StarMarkerPresentation.fillStyle(
                taskIsRoot: true,
                taskIsStarred: false,
                renderMode: .active,
                isHoveringRow: false,
                isHoveringMarker: true
            ),
            .primaryText(opacity: 1)
        )
    }

    func testUnstarredRootRowHoverUsesDarkPreviewFill() {
        XCTAssertEqual(
            StarMarkerPresentation.fillStyle(
                taskIsRoot: true,
                taskIsStarred: false,
                renderMode: .active,
                isHoveringRow: true,
                isHoveringMarker: false
            ),
            .primaryText(opacity: DesignTokens.Spacing.starMarkerPreviewOpacity)
        )
    }

    func testUnstarredRootIgnoresStaleMarkerHoverAfterStarStateChanges() {
        let hoverState = StarMarkerPresentation.hoverStateAfterStarStateChange(
            wasHoveringRow: true,
            wasHoveringMarker: true,
            suppressesMarkerHoverUntilExit: false
        )

        XCTAssertFalse(hoverState.isHoveringRow)
        XCTAssertFalse(hoverState.isHoveringMarker)
        XCTAssertTrue(hoverState.suppressesMarkerHoverUntilExit)
        XCTAssertEqual(
            StarMarkerPresentation.fillStyle(
                taskIsRoot: true,
                taskIsStarred: false,
                renderMode: .active,
                isHoveringRow: hoverState.isHoveringRow,
                isHoveringMarker: hoverState.isHoveringMarker
            ),
            .clear
        )
    }

    func testSuppressedMarkerHoverIgnoresReenteredHoverUntilMouseExits() {
        let staleHover = StarMarkerPresentation.hoverStateAfterMarkerHoverChange(
            isHoveringMarker: true,
            isHoveringRow: false,
            suppressesMarkerHoverUntilExit: true
        )

        XCTAssertFalse(staleHover.isHoveringMarker)
        XCTAssertTrue(staleHover.suppressesMarkerHoverUntilExit)
        XCTAssertEqual(
            StarMarkerPresentation.fillStyle(
                taskIsRoot: false,
                taskIsStarred: false,
                renderMode: .active,
                isHoveringRow: staleHover.isHoveringRow,
                isHoveringMarker: staleHover.isHoveringMarker
            ),
            .clear
        )

        let exitedHover = StarMarkerPresentation.hoverStateAfterMarkerHoverChange(
            isHoveringMarker: false,
            isHoveringRow: staleHover.isHoveringRow,
            suppressesMarkerHoverUntilExit: staleHover.suppressesMarkerHoverUntilExit
        )

        XCTAssertFalse(exitedHover.isHoveringMarker)
        XCTAssertFalse(exitedHover.suppressesMarkerHoverUntilExit)
    }
}
