import XCTest
@testable import TodoApp

final class InterfaceDensityTokenTests: XCTestCase {
    func testDenseModeUsesEightyPercentScale() {
        XCTAssertEqual(InterfaceDensity.regular.scale, 1)
        XCTAssertEqual(InterfaceDensity.dense.scale, 0.8)
    }

    func testRegularDensityKeepsCurrentTaskRowBaseline() {
        XCTAssertEqual(DesignTokens.Spacing.scaledRowVertical(in: .regular), 8)
        XCTAssertEqual(DesignTokens.Spacing.scaledRowHorizontal(in: .regular), 12)
        XCTAssertEqual(DesignTokens.Typography.bodySize(in: .regular), 15)
    }

    func testDenseDensityScalesTaskRowVisualTokensToEightyPercent() {
        XCTAssertEqual(DesignTokens.Spacing.scaledRowVertical(in: .dense), 6.4)
        XCTAssertEqual(DesignTokens.Spacing.scaledRowHorizontal(in: .dense), 9.6)
        XCTAssertEqual(DesignTokens.Typography.bodySize(in: .dense), 12)
    }

    func testDenseDensityScalesInteractionTargetsToEightyPercent() {
        XCTAssertEqual(DesignTokens.Size.scaledCheckbox(in: .dense), 11.2)
        XCTAssertEqual(DesignTokens.Size.scaledCheckboxTapTarget(in: .dense), 19.2)
        XCTAssertEqual(DesignTokens.Size.scaledTrailingControl(in: .dense), 19.2)
        XCTAssertEqual(DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: .dense), 12.8)
    }

    func testDenseDensityScalesDueDateLayoutWithTheSameRatio() {
        XCTAssertEqual(DueDateLabelLayout.scaledTextTrailingInset(in: .dense), 5.6)
        XCTAssertEqual(
            DueDateLabelLayout.tagWidth(for: "Due Today", density: .dense),
            DueDateLabelLayout.tagWidth(for: "Due Today", density: .regular) * 0.8,
            accuracy: 1
        )
    }
}
