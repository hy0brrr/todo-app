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
}
