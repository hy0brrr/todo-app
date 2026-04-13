import XCTest
@testable import TodoApp

final class EditingLayerInteractivityTests: XCTestCase {
    func testStaticDisplayStopsReceivingHitsWhileEditing() {
        XCTAssertFalse(EditingLayerInteractivity.shouldAllowStaticDisplayHitTesting(isEditing: true))
    }

    func testStaticDisplayReceivesHitsWhenNotEditing() {
        XCTAssertTrue(EditingLayerInteractivity.shouldAllowStaticDisplayHitTesting(isEditing: false))
    }

    func testEndEditingDoesNotCommitBeforeEditingActuallyBegins() {
        XCTAssertFalse(
            EditingLayerInteractivity.shouldCommitOnEndEditing(
                didBeginEditing: false,
                didCommitFromCommand: false,
                didCancelFromCommand: false
            )
        )
    }

    func testEndEditingCommitsAfterEditingBeginsAndNoExplicitCommandHandled() {
        XCTAssertTrue(
            EditingLayerInteractivity.shouldCommitOnEndEditing(
                didBeginEditing: true,
                didCommitFromCommand: false,
                didCancelFromCommand: false
            )
        )
    }
}
