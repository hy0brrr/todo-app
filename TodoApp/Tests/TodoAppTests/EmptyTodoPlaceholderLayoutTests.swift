import CoreGraphics
import XCTest
@testable import TodoApp

final class EmptyTodoPlaceholderLayoutTests: XCTestCase {
    func testImageSideKeepsFixedArtworkSizeInLargeSpace() {
        let side = EmptyTodoPlaceholderLayout.imageSide(for: CGSize(width: 400, height: 200))

        XCTAssertEqual(side, 80)
    }

    func testImageSideKeepsFixedArtworkSizeInLargeSquareSpace() {
        let side = EmptyTodoPlaceholderLayout.imageSide(for: CGSize(width: 1000, height: 1000))

        XCTAssertEqual(side, 80)
    }
}
