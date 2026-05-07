import XCTest
import AppKit
@testable import TodoApp

final class ClickOutsideHitTestingTests: XCTestCase {
    func testTextFieldDescendantCountsAsEditingHitView() {
        let textField = NSTextField(frame: .zero)
        let nestedView = NSView(frame: .zero)
        textField.addSubview(nestedView)

        XCTAssertTrue(ClickOutsideHitTesting.isTextEditingView(nestedView))
        XCTAssertFalse(ClickOutsideHitTesting.shouldTreatAsOutsideClick(hitView: nestedView))
    }

    func testDirectTextViewCountsAsEditingHitView() {
        let textView = NSTextView(frame: .zero)

        XCTAssertTrue(ClickOutsideHitTesting.isTextEditingView(textView))
        XCTAssertFalse(ClickOutsideHitTesting.shouldTreatAsOutsideClick(hitView: textView))
    }

    func testPlainViewStillCountsAsOutsideClick() {
        XCTAssertFalse(ClickOutsideHitTesting.isTextEditingView(NSView(frame: .zero)))
        XCTAssertTrue(ClickOutsideHitTesting.shouldTreatAsOutsideClick(hitView: NSView(frame: .zero)))
        XCTAssertTrue(ClickOutsideHitTesting.shouldTreatAsOutsideClick(hitView: nil))
    }

    func testEditingSessionCommitsWhenMouseDownHitsOutsideEditor() {
        XCTAssertTrue(
            ClickOutsideHitTesting.shouldCommitEditingOnMouseDown(
                isEditing: true,
                hitView: NSView(frame: .zero)
            )
        )
    }

    func testEditingSessionDoesNotCommitWhenMouseDownHitsEditor() {
        XCTAssertFalse(
            ClickOutsideHitTesting.shouldCommitEditingOnMouseDown(
                isEditing: true,
                isInsideEditorBounds: false,
                hitView: NSTextView(frame: .zero)
            )
        )
    }

    func testEditingSessionDoesNotCommitInsideEditorBoundsEvenWhenHitViewIsContainer() {
        XCTAssertFalse(
            ClickOutsideHitTesting.shouldCommitEditingOnMouseDown(
                isEditing: true,
                isInsideEditorBounds: true,
                hitView: NSView(frame: .zero)
            )
        )
    }

    func testInactiveEditingSessionIgnoresOutsideMouseDown() {
        XCTAssertFalse(
            ClickOutsideHitTesting.shouldCommitEditingOnMouseDown(
                isEditing: false,
                hitView: NSView(frame: .zero)
            )
        )
    }
}
