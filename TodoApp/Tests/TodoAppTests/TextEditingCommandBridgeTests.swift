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

    func testCommandZMapsToUndoCommand() {
        XCTAssertEqual(
            TextEditingCommandBridge.action(
                forCharactersIgnoringModifiers: "z",
                modifierFlags: [.command]
            ),
            .undo
        )
    }

    func testCommandShiftZMapsToRedoCommand() {
        XCTAssertEqual(
            TextEditingCommandBridge.action(
                forCharactersIgnoringModifiers: "z",
                modifierFlags: [.command, .shift]
            ),
            .redo
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

    func testAddTaskInputAppliesClearedBindingWhileEditorIsActive() {
        XCTAssertEqual(
            AddTaskInputSynchronization.textFieldValueToApply(
                displayedText: "New task",
                bindingText: "",
                isEditing: true
            ),
            ""
        )
    }

    func testAddTaskInputDoesNotOverwriteActiveTypingWithStaleBinding() {
        XCTAssertNil(
            AddTaskInputSynchronization.textFieldValueToApply(
                displayedText: "New task",
                bindingText: "New",
                isEditing: true
            )
        )
    }

    func testDraftInputCommandHandlingTreatsEscapeAsCancel() {
        XCTAssertEqual(
            DraftTaskInputCommandHandling.action(for: #selector(NSResponder.cancelOperation(_:))),
            .cancel
        )
    }
}
