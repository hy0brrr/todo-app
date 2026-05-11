import XCTest
import AppKit
@testable import TodoApp

final class TextEditingCommandBridgeTests: XCTestCase {
    func testCommandVMapsToPasteSelector() {
        XCTAssertEqual(
            TextEditingCommandBridge.selector(
                forCharactersIgnoringModifiers: "v",
                modifierFlags: [.command]
            ),
            #selector(NSText.paste(_:))
        )
    }

    func testCommandCMapsToCopySelector() {
        XCTAssertEqual(
            TextEditingCommandBridge.selector(
                forCharactersIgnoringModifiers: "c",
                modifierFlags: [.command]
            ),
            #selector(NSText.copy(_:))
        )
    }

    func testNonCommandKeyDoesNotMapToTextEditingSelector() {
        XCTAssertNil(
            TextEditingCommandBridge.selector(
                forCharactersIgnoringModifiers: "v",
                modifierFlags: []
            )
        )
    }
}
