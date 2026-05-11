import XCTest
import AppKit
@testable import TodoApp

final class FallingCompletedLayoutTests: XCTestCase {
    func testGravityIsFiftyPercentFasterThanOriginalTuning() {
        XCTAssertEqual(FallingCompletedPhysics.gravity.dx, 0, accuracy: 0.001)
        XCTAssertEqual(FallingCompletedPhysics.gravity.dy, -8.7, accuracy: 0.001)
    }

    func testLetterBodySizeIncreasesPileDensityByFiftySixPercentFromOriginalTuning() {
        let bodySize = FallingCompletedPhysics.letterBodySize(
            for: CGSize(width: 20, height: 30),
            fontSize: 14
        )

        let expectedScale = 1 / sqrt(1.56)
        XCTAssertEqual(bodySize.width, 20 * expectedScale, accuracy: 0.001)
        XCTAssertEqual(bodySize.height, 30 * expectedScale, accuracy: 0.001)
    }

    func testScenePointUsesRowCenterAndFlipsYAxis() {
        let point = FallingCompletedLayout.scenePoint(
            for: CGRect(x: 40, y: 120, width: 200, height: 30),
            sceneSize: CGSize(width: 400, height: 700)
        )

        XCTAssertEqual(point.x, 140, accuracy: 0.001)
        XCTAssertEqual(point.y, 565, accuracy: 0.001)
    }

    func testScenePointFallsBackNearTopWhenFrameIsMissing() {
        let point = FallingCompletedLayout.scenePoint(
            for: nil,
            sceneSize: CGSize(width: 400, height: 700)
        )

        XCTAssertEqual(point.x, 72, accuracy: 0.001)
        XCTAssertEqual(point.y, 644, accuracy: 0.001)
    }

    func testLetterPositionsPreserveOriginalRowHorizontalPlacement() {
        let positions = FallingCompletedLayout.letterPositions(
            count: 4,
            sourceFrame: CGRect(x: 40, y: 120, width: 200, height: 30),
            sceneSize: CGSize(width: 400, height: 700),
            fontSize: 10,
            rowIndex: 0
        )

        XCTAssertEqual(positions.map { round($0.x) }, [40, 46, 52, 57])
        XCTAssertEqual(positions.map { round($0.y) }, [565, 565, 565, 565])
    }

    func testReleaseDelayFallsFromRightToLeft() {
        let delays = (0..<4).map {
            FallingCompletedLayout.releaseDelay(
                sourceIndex: $0,
                visibleCount: 4,
                rowIndex: 0
            )
        }

        zip(delays, [0.054, 0.036, 0.018, 0.0]).forEach { actual, expected in
            XCTAssertEqual(actual, expected, accuracy: 0.0001)
        }
    }

    func testInitialCompletedDropPositionsStartAboveFloorAndSpreadAcrossCard() {
        let bounds = CGRect(x: 42, y: 20, width: 684, height: 650)
        let visibleBounds = CGRect(x: 42, y: 20, width: 684, height: 448)
        let positions = (0..<5).map {
            FallingCompletedLayout.initialDropPosition(
                visibleIndex: $0,
                totalVisibleCount: 5,
                rowIndex: 1,
                physicsBounds: bounds,
                visibleBounds: visibleBounds,
                fontSize: 18
            )
        }

        XCTAssertEqual(positions.map { round($0.x) }, [156, 270, 384, 498, 612])
        XCTAssertTrue(positions.allSatisfy { $0.y > bounds.minY + 260 })
        XCTAssertTrue(positions.allSatisfy { $0.y < visibleBounds.maxY })
    }

    func testInitialCompletedDropDelayIsStaggeredByRowAndLetter() {
        XCTAssertEqual(
            FallingCompletedLayout.initialDropDelay(sourceIndex: 2, rowIndex: 3),
            0.37,
            accuracy: 0.0001
        )
    }

    func testPhysicsBoundsInsetCompletedCardSidesAndFloor() {
        let bounds = FallingCompletedLayout.physicsBounds(
            for: CGRect(x: 26, y: 740, width: 716, height: 480),
            sceneSize: CGSize(width: 768, height: 1224),
            inset: 16
        )

        XCTAssertEqual(bounds.minX, 42, accuracy: 0.001)
        XCTAssertEqual(bounds.width, 684, accuracy: 0.001)
        XCTAssertEqual(bounds.minY, 20, accuracy: 0.001)
        XCTAssertEqual(bounds.height, 1384, accuracy: 0.001)
    }

    func testPhysicsBoundsFallBackToFullSceneWhenCardFrameIsMissing() {
        let bounds = FallingCompletedLayout.physicsBounds(
            for: nil,
            sceneSize: CGSize(width: 400, height: 700),
            inset: 16
        )

        XCTAssertEqual(bounds.minX, 16, accuracy: 0.001)
        XCTAssertEqual(bounds.width, 368, accuracy: 0.001)
        XCTAssertEqual(bounds.minY, 16, accuracy: 0.001)
    }

    func testCompletedVisibleBoundsUseCardInteriorOnly() {
        let bounds = FallingCompletedLayout.completedVisibleBounds(
            for: CGRect(x: 26, y: 740, width: 716, height: 480),
            sceneSize: CGSize(width: 768, height: 1224),
            inset: 16
        )

        XCTAssertEqual(bounds.minX, 42, accuracy: 0.001)
        XCTAssertEqual(bounds.minY, 20, accuracy: 0.001)
        XCTAssertEqual(bounds.width, 684, accuracy: 0.001)
        XCTAssertEqual(bounds.height, 448, accuracy: 0.001)
    }

    func testSweepTriggerYStaysBelowCompletedDividerByClearance() {
        let triggerY = FallingCompletedLayout.sweepTriggerY(
            for: CGRect(x: 42, y: 168, width: 684, height: 1),
            sceneSize: CGSize(width: 768, height: 1224),
            fallbackVisibleBounds: CGRect(x: 42, y: 20, width: 684, height: 448),
            clearance: 16
        )

        XCTAssertEqual(triggerY, 1039, accuracy: 0.001)
    }

    func testSweepTriggerYFallsBackToVisibleTopMinusClearance() {
        let triggerY = FallingCompletedLayout.sweepTriggerY(
            for: nil,
            sceneSize: CGSize(width: 768, height: 1224),
            fallbackVisibleBounds: CGRect(x: 42, y: 20, width: 684, height: 448),
            clearance: 16
        )

        XCTAssertEqual(triggerY, 452, accuracy: 0.001)
    }

    func testSweepTriggersWhenSettledPileReachesDividerClearance() {
        let almostFull = CGRect(x: 100, y: 1006, width: 20, height: 32)
        let full = CGRect(x: 100, y: 1007, width: 20, height: 32)

        XCTAssertFalse(FallingCompletedPhysics.shouldSweep(letterFrames: [almostFull], triggerY: 1039))
        XCTAssertTrue(FallingCompletedPhysics.shouldSweep(letterFrames: [full], triggerY: 1039))
    }

    func testFallingLetterColorMatchesActiveTaskTextColor() throws {
        let letterColor = try XCTUnwrap(FallingCompletedPresentation.letterTextColor.usingColorSpace(.sRGB))
        let activeTaskColor = try XCTUnwrap(NSColor(DesignTokens.ColorRole.primaryText).usingColorSpace(.sRGB))

        XCTAssertEqual(letterColor.alphaComponent, 1, accuracy: 0.001)
        XCTAssertEqual(letterColor.redComponent, activeTaskColor.redComponent, accuracy: 0.001)
        XCTAssertEqual(letterColor.greenComponent, activeTaskColor.greenComponent, accuracy: 0.001)
        XCTAssertEqual(letterColor.blueComponent, activeTaskColor.blueComponent, accuracy: 0.001)
    }

    func testSweepDoesNotTriggerWithoutLetters() {
        XCTAssertFalse(FallingCompletedPhysics.shouldSweep(
            letterFrames: [],
            triggerY: 1039
        ))
    }
}
