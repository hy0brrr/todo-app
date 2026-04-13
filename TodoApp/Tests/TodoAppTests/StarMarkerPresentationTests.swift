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
}
