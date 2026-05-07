import CoreGraphics
import XCTest
@testable import TodoApp

final class PartitionAreaLayoutTests: XCTestCase {
    func testScrollsWhenActualPartitionStackOverflowsVisibleArea() {
        let layout = PartitionAreaLayout.calculate(
            contentHeight: 760,
            partitionHeights: [320, 320],
            partitionMinHeight: 200,
            completedMinHeight: 200,
            handleGap: 16
        )

        XCTAssertGreaterThan(layout.partitionStackHeight, layout.partitionsAreaHeight)
        XCTAssertTrue(layout.shouldScrollPartitions)
    }
}
