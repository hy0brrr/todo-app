import SwiftUI
import AppKit

enum InterfaceDensity: String, CaseIterable, Identifiable {
    case regular
    case dense

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .regular:
            return 1
        case .dense:
            return 0.8
        }
    }
}

private struct InterfaceDensityEnvironmentKey: EnvironmentKey {
    static let defaultValue: InterfaceDensity = .regular
}

extension EnvironmentValues {
    var interfaceDensity: InterfaceDensity {
        get { self[InterfaceDensityEnvironmentKey.self] }
        set { self[InterfaceDensityEnvironmentKey.self] = newValue }
    }
}

enum DesignTokens {
    static func scaled(_ value: CGFloat, in density: InterfaceDensity) -> CGFloat {
        ((value * density.scale) * 1_000).rounded() / 1_000
    }

    enum Spacing {
        // SwiftUI layout values are measured in points (pt) on macOS.
        static let screenHorizontalInset: CGFloat = 16
        static let screenVerticalInset: CGFloat = 16
        // The hidden titlebar controls already consume part of the perceived top spacing,
        // so the actual inset stays smaller than the visual 16pt target.
        static let screenTopInset: CGFloat = 2
        static let cardGap: CGFloat = 16
        static let sectionPaddingHorizontal: CGFloat = 18
        static let sectionPaddingVertical: CGFloat = 14
        static let sectionPaddingVerticalRelaxed: CGFloat = 16
        static let cardHeaderTop: CGFloat = 18
        static let cardHeaderBottom: CGFloat = 8
        static let cardHeaderRuleGap: CGFloat = 14
        static let sectionBodyTop: CGFloat = 2
        static let screenHeaderTop: CGFloat = 8
        static let screenHeaderBottom: CGFloat = 18
        static let windowChromeHoverHeight: CGFloat = 52
        static let windowChromeContentInset: CGFloat = 28
        static let listEmptyHorizontal: CGFloat = 16
        static let listEmptyVertical: CGFloat = 14
        static let rowHorizontal: CGFloat = 12
        static let rowVertical: CGFloat = 8
        static let taskLeadingGap: CGFloat = 4
        static let taskDueDateGap: CGFloat = 12
        static let taskUnsetDueDateGap: CGFloat = 4
        static let taskMetaGap: CGFloat = 5
        static let tagGap: CGFloat = 6
        static let inlineTagTextGap: CGFloat = 6
        static let childTaskIndent: CGFloat = 18
        static let partitionTitleIconOpticalOffsetX: CGFloat = -0.5
        static let addTaskPlusOpticalOffsetX: CGFloat = -0.5
        static let checkboxTitleOverhang: CGFloat = 2
        static let starMarkerLeadingOffset: CGFloat = 11
        static let dueDateTagHorizontal: CGFloat = 7
        static let dueDateTagVertical: CGFloat = 2
        static let starMarkerPreviewOpacity: Double = 0.72
        static let inputHorizontal: CGFloat = 8
        static let inputVertical: CGFloat = 6
        static let modalHorizontal: CGFloat = 16
        static let modalHeaderVertical: CGFloat = 12
        static let modalFooterVertical: CGFloat = 10
        static let modalListRowVertical: CGFloat = 3
        static let editorSectionGap: CGFloat = 12
        static let cardHeaderGap: CGFloat = 12
        static let cardTitleGap: CGFloat = 4
        static let partitionTitleInlineGap: CGFloat = 8
        static let partitionHeaderContentLeadingInset: CGFloat = 4
        static let calendarGridGap: CGFloat = 6
        static let calendarHeaderControlGap: CGFloat = 8
        static let calendarPopoverHorizontal: CGFloat = 14
        static let calendarPopoverVertical: CGFloat = 14

        static func scaledScreenHorizontalInset(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(screenHorizontalInset, in: density) }
        static func scaledScreenVerticalInset(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(screenVerticalInset, in: density) }
        static func scaledScreenTopInset(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(screenTopInset, in: density) }
        static func scaledCardGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardGap, in: density) }
        static func scaledSectionPaddingHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(sectionPaddingHorizontal, in: density) }
        static func scaledSectionPaddingVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(sectionPaddingVertical, in: density) }
        static func scaledSectionPaddingVerticalRelaxed(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(sectionPaddingVerticalRelaxed, in: density) }
        static func scaledCardHeaderTop(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardHeaderTop, in: density) }
        static func scaledCardHeaderBottom(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardHeaderBottom, in: density) }
        static func scaledCardHeaderRuleGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardHeaderRuleGap, in: density) }
        static func scaledSectionBodyTop(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(sectionBodyTop, in: density) }
        static func scaledScreenHeaderTop(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(screenHeaderTop, in: density) }
        static func scaledScreenHeaderBottom(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(screenHeaderBottom, in: density) }
        static func scaledListEmptyHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(listEmptyHorizontal, in: density) }
        static func scaledListEmptyVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(listEmptyVertical, in: density) }
        static func scaledRowHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(rowHorizontal, in: density) }
        static func scaledRowVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(rowVertical, in: density) }
        static func scaledTaskLeadingGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(taskLeadingGap, in: density) }
        static func scaledTaskDueDateGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(taskDueDateGap, in: density) }
        static func scaledTaskUnsetDueDateGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(taskUnsetDueDateGap, in: density) }
        static func scaledTaskMetaGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(taskMetaGap, in: density) }
        static func scaledTagGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(tagGap, in: density) }
        static func scaledInlineTagTextGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(inlineTagTextGap, in: density) }
        static func scaledChildTaskIndent(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(childTaskIndent, in: density) }
        static func scaledCheckboxTitleOverhang(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(checkboxTitleOverhang, in: density) }
        static func scaledStarMarkerLeadingOffset(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(starMarkerLeadingOffset, in: density) }
        static func scaledDueDateTagHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(dueDateTagHorizontal, in: density) }
        static func scaledDueDateTagVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(dueDateTagVertical, in: density) }
        static func scaledInputHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(inputHorizontal, in: density) }
        static func scaledInputVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(inputVertical, in: density) }
        static func scaledModalHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalHorizontal, in: density) }
        static func scaledModalHeaderVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalHeaderVertical, in: density) }
        static func scaledModalFooterVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalFooterVertical, in: density) }
        static func scaledModalListRowVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalListRowVertical, in: density) }
        static func scaledEditorSectionGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(editorSectionGap, in: density) }
        static func scaledCardHeaderGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardHeaderGap, in: density) }
        static func scaledCardTitleGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardTitleGap, in: density) }
        static func scaledPartitionTitleInlineGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleInlineGap, in: density) }
        static func scaledPartitionHeaderContentLeadingInset(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionHeaderContentLeadingInset, in: density) }
        static func scaledCalendarGridGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarGridGap, in: density) }
        static func scaledCalendarHeaderControlGap(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarHeaderControlGap, in: density) }
        static func scaledCalendarPopoverHorizontal(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarPopoverHorizontal, in: density) }
        static func scaledCalendarPopoverVertical(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarPopoverVertical, in: density) }
    }

    enum Radius {
        static let card: CGFloat = 14
        static let row: CGFloat = 8
        static let field: CGFloat = 7
        static let checkbox: CGFloat = 4
        static let pill: CGFloat = 8
        static let titleTag: CGFloat = 6
        static let dueDateTag: CGFloat = 5
        static let calendarDay: CGFloat = 9
        static let calendarNavButton: CGFloat = 8
        static let starMarker: CGFloat = 2
        static let emojiPlate: CGFloat = 12

        static func scaledCard(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(card, in: density) }
        static func scaledRow(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(row, in: density) }
        static func scaledField(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(field, in: density) }
        static func scaledCheckbox(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(checkbox, in: density) }
        static func scaledPill(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(pill, in: density) }
        static func scaledTitleTag(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(titleTag, in: density) }
        static func scaledDueDateTag(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(dueDateTag, in: density) }
        static func scaledCalendarDay(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarDay, in: density) }
        static func scaledCalendarNavButton(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarNavButton, in: density) }
        static func scaledStarMarker(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(starMarker, in: density) }
        static func scaledEmojiPlate(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(emojiPlate, in: density) }
    }

    enum Stroke {
        static let cardLineWidth: CGFloat = 1
        static let checkboxLineWidth: CGFloat = 1.5
        static let dueDateOutlineLineWidth: CGFloat = 0.8
        static let headerRuleLineWidth: CGFloat = 0.5
        static let cardOpacity: Double = 0.48
        static let dividerOpacity: Double = 0.10

        static func scaledCardLineWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(cardLineWidth, in: density) }
        static func scaledCheckboxLineWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(checkboxLineWidth, in: density) }
        static func scaledDueDateOutlineLineWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(dueDateOutlineLineWidth, in: density) }
        static func scaledHeaderRuleLineWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(headerRuleLineWidth, in: density) }
    }

    enum Shadow {
        static let cardOpacity: Double = 0.08
        static let cardRadius: CGFloat = 24
        static let cardYOffset: CGFloat = 10
        static let shellOpacity: Double = 0.08
        static let shellRadius: CGFloat = 24
        static let shellYOffset: CGFloat = 12
    }

    enum Typography {
        private static func appFont(
            size: CGFloat,
            role: AppFontWeightRole,
            fallbackWeight: Font.Weight,
            design: Font.Design = .rounded
        ) -> Font {
            let fontName: String?

            switch role {
            case .regular:
                fontName = "PingFangSC-Regular"
            case .medium:
                fontName = "PingFangSC-Medium"
            case .semibold, .bold, .heavy:
                fontName = "PingFangSC-Semibold"
            }

            if let fontName, NSFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }

            return .system(size: size, weight: fallbackWeight, design: design)
        }

        private static func titleFont(
            size: CGFloat,
            fallbackWeight: Font.Weight,
            design: Font.Design = .rounded
        ) -> Font {
            let fontName = "PPNeueMontrealVariable-SemiBold"

            if NSFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }

            return .system(size: size, weight: fallbackWeight, design: design)
        }

        static func screenTitleSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(30, in: density) }
        static func screenSubtitleSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(14, in: density) }
        static func partitionHeaderSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(12, in: density) }
        static func partitionHeaderTitleSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(16, in: density) }
        static func partitionMetaSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(12, in: density) }
        static func bodySize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(15, in: density) }
        static func modalTitleSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(15, in: density) }
        static func bodyMediumSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(14, in: density) }
        static func captionSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(13, in: density) }
        static func microSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(12, in: density) }
        static func dueDateTagSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(11, in: density) }
        static func iconSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(12, in: density) }
        static func starSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(13, in: density) }
        static func checkmarkSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(8, in: density) }
        static func emojiSize(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(38, in: density) }

        static var screenTitle: Font { screenTitle(in: .regular) }
        static var screenSubtitle: Font { screenSubtitle(in: .regular) }
        static var partitionHeader: Font { partitionHeader(in: .regular) }
        static var partitionHeaderTitle: Font { partitionHeaderTitle(in: .regular) }
        static var partitionMeta: Font { partitionMeta(in: .regular) }
        static let partitionHeaderTracking: CGFloat = 0
        static var body: Font { body(in: .regular) }
        static var modalTitle: Font { modalTitle(in: .regular) }
        static var bodyMedium: Font { bodyMedium(in: .regular) }
        static var caption: Font { caption(in: .regular) }
        static var captionStrong: Font { captionStrong(in: .regular) }
        static var micro: Font { micro(in: .regular) }
        static var dueDateTag: Font { dueDateTag(in: .regular) }
        static var icon: Font { icon(in: .regular) }
        static var star: Font { star(in: .regular) }
        static var checkmark: Font { checkmark(in: .regular) }
        static var emoji: Font { emoji(in: .regular) }

        static func screenTitle(in density: InterfaceDensity) -> Font { appFont(size: screenTitleSize(in: density), role: .semibold, fallbackWeight: .semibold) }
        static func screenSubtitle(in density: InterfaceDensity) -> Font { appFont(size: screenSubtitleSize(in: density), role: .medium, fallbackWeight: .medium) }
        static func partitionHeader(in density: InterfaceDensity) -> Font { appFont(size: partitionHeaderSize(in: density), role: .semibold, fallbackWeight: .semibold) }
        static func partitionHeaderTitle(in density: InterfaceDensity) -> Font { titleFont(size: partitionHeaderTitleSize(in: density), fallbackWeight: .bold) }
        static func partitionMeta(in density: InterfaceDensity) -> Font { appFont(size: partitionMetaSize(in: density), role: .medium, fallbackWeight: .medium) }
        static func body(in density: InterfaceDensity) -> Font { appFont(size: bodySize(in: density), role: .regular, fallbackWeight: .regular) }
        static func modalTitle(in density: InterfaceDensity) -> Font { appFont(size: modalTitleSize(in: density), role: .bold, fallbackWeight: .bold) }
        static func bodyMedium(in density: InterfaceDensity) -> Font { appFont(size: bodyMediumSize(in: density), role: .medium, fallbackWeight: .medium) }
        static func caption(in density: InterfaceDensity) -> Font { appFont(size: captionSize(in: density), role: .medium, fallbackWeight: .medium) }
        static func captionStrong(in density: InterfaceDensity) -> Font { appFont(size: captionSize(in: density), role: .bold, fallbackWeight: .bold) }
        static func micro(in density: InterfaceDensity) -> Font { appFont(size: microSize(in: density), role: .medium, fallbackWeight: .medium) }
        static func dueDateTag(in density: InterfaceDensity) -> Font { appFont(size: dueDateTagSize(in: density), role: .regular, fallbackWeight: .regular) }
        static func icon(in density: InterfaceDensity) -> Font { appFont(size: iconSize(in: density), role: .semibold, fallbackWeight: .semibold) }
        static func star(in density: InterfaceDensity) -> Font { appFont(size: starSize(in: density), role: .medium, fallbackWeight: .medium) }
        static func checkmark(in density: InterfaceDensity) -> Font { appFont(size: checkmarkSize(in: density), role: .bold, fallbackWeight: .bold, design: .default) }
        static func emoji(in density: InterfaceDensity) -> Font { appFont(size: emojiSize(in: density), role: .regular, fallbackWeight: .regular, design: .default) }
    }

    enum Size {
        private static func dueDateTextContentWidthValue(in density: InterfaceDensity = .regular) -> CGFloat {
            let fontSize = Typography.dueDateTagSize(in: density)
            let font = NSFont(name: "PingFangSC-Regular", size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .regular)
            return ["Due Tomorrow", "Due Yesterday"]
                .map { ($0 as NSString).size(withAttributes: [.font: font]).width }
                .max()
                .map(ceil) ?? 0
        }

        private static func dueDateColumnWidthValue(in density: InterfaceDensity = .regular) -> CGFloat {
            let widestLabel = scaledDueDateTextContentWidth(in: density)
            let widestDueContent = max(
                ceil(widestLabel + (Spacing.scaledDueDateTagHorizontal(in: density) * 2)),
                scaledTrailingControl(in: density)
            )
            let trailingInset = Spacing.scaledSectionPaddingHorizontal(in: density)
                + Spacing.scaledPartitionHeaderContentLeadingInset(in: density)
                - Spacing.scaledRowHorizontal(in: density)
            let leadingPadding = max(
                Spacing.scaledTaskDueDateGap(in: density) - Spacing.scaledTaskLeadingGap(in: density),
                0
            )

            return ceil(leadingPadding + widestDueContent + trailingInset)
        }

        static let partitionIndicator: CGFloat = 8
        static let checkbox: CGFloat = 14
        static let checkboxTapTarget: CGFloat = 24
        static let partitionTitleRowHeight: CGFloat = 20
        static let inlineTextEditorHeight: CGFloat = 20
        static let starMarkerWidth: CGFloat = 3
        static let starMarkerHeight: CGFloat = 18
        static let starMarkerTapTargetWidth: CGFloat = 16
        static let trailingControl: CGFloat = 24
        static let dueDateTextContentWidth: CGFloat = dueDateTextContentWidthValue()
        static let dueDateColumnWidth: CGFloat = dueDateColumnWidthValue()
        static let partitionColorDot: CGFloat = 14
        static let modalPartitionDot: CGFloat = 10
        static let tagChipHeight: CGFloat = 22
        static let resizeHandleHeight: CGFloat = 6
        static let partitionMinHeight: CGFloat = 200
        static let completedMinHeight: CGFloat = 200
        static let modalWidth: CGFloat = 330
        static let taskEditorWidth: CGFloat = 296
        static let modalMinHeight: CGFloat = 300
        static let modalMaxHeight: CGFloat = 500
        static let appMinWidth: CGFloat = 300
        static let appIdealWidth: CGFloat = 380
        static let appMaxWidth: CGFloat = .infinity
        static let appMinHeight: CGFloat = 560
        static let datePopoverWidth: CGFloat = 260
        static let calendarDayCell: CGFloat = 28
        static let calendarNavControl: CGFloat = 24
        static let emojiPlate: CGFloat = 48
        static let partitionTitleIcon: CGFloat = 15
        static let partitionTitleIconInnerStroke: CGFloat = 2.4
        static let partitionTitleIconOuterStroke: CGFloat = 3.8
        static let partitionTitleIconArmLength: CGFloat = 7.6
        static let partitionTitleIconArmOffset: CGFloat = 2.8
        static let topGlow: CGFloat = 280

        static func scaledPartitionIndicator(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionIndicator, in: density) }
        static func scaledCheckbox(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(checkbox, in: density) }
        static func scaledCheckboxTapTarget(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(checkboxTapTarget, in: density) }
        static func scaledPartitionTitleRowHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleRowHeight, in: density) }
        static func scaledInlineTextEditorHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(inlineTextEditorHeight, in: density) }
        static func scaledStarMarkerWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(starMarkerWidth, in: density) }
        static func scaledStarMarkerHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(starMarkerHeight, in: density) }
        static func scaledStarMarkerTapTargetWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(starMarkerTapTargetWidth, in: density) }
        static func scaledTrailingControl(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(trailingControl, in: density) }
        static func scaledDueDateTextContentWidth(in density: InterfaceDensity) -> CGFloat { dueDateTextContentWidthValue(in: density) }
        static func scaledDueDateColumnWidth(in density: InterfaceDensity) -> CGFloat { dueDateColumnWidthValue(in: density) }
        static func scaledTagChipHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(tagChipHeight, in: density) }
        static func scaledResizeHandleHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(resizeHandleHeight, in: density) }
        static func scaledPartitionMinHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionMinHeight, in: density) }
        static func scaledCompletedMinHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(completedMinHeight, in: density) }
        static func scaledModalWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalWidth, in: density) }
        static func scaledModalMinHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalMinHeight, in: density) }
        static func scaledModalMaxHeight(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(modalMaxHeight, in: density) }
        static func scaledTaskEditorWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(taskEditorWidth, in: density) }
        static func scaledDatePopoverWidth(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(datePopoverWidth, in: density) }
        static func scaledCalendarDayCell(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarDayCell, in: density) }
        static func scaledCalendarNavControl(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(calendarNavControl, in: density) }
        static func scaledEmojiPlate(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(emojiPlate, in: density) }
        static func scaledPartitionTitleIcon(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleIcon, in: density) }
        static func scaledPartitionTitleIconInnerStroke(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleIconInnerStroke, in: density) }
        static func scaledPartitionTitleIconOuterStroke(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleIconOuterStroke, in: density) }
        static func scaledPartitionTitleIconArmLength(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleIconArmLength, in: density) }
        static func scaledPartitionTitleIconArmOffset(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(partitionTitleIconArmOffset, in: density) }
        static func scaledTopGlow(in density: InterfaceDensity) -> CGFloat { DesignTokens.scaled(topGlow, in: density) }
    }

    enum Motion {
        static let quick: Double = 0.15
        static let hoverScale: CGFloat = 1.15
        static let starHoverScale: CGFloat = 1.2
        static let dueDateHoverScale: CGFloat = 1.05
    }

    enum Opacity {
        static let rowHoverFill: Double = 0.10
        static let inputFill: Double = 0.55
        static let footerFill: Double = 0.30
        static let resizeHoverFill: Double = 0.24
        static let editPanelFill: Double = 0.34
        static let secondaryWhenHidden: Double = 0
        static let glassTop: Double = 0.36
        static let glassBottom: Double = 0.16
        static let textSecondary: Double = 0.68
        static let textTertiary: Double = 0.44
        static let emojiPlateFill: Double = 0.34
        static let stripe: Double = 0.14
        static let shellTint: Double = 0.14
        static let shellGlow: Double = 0.12
    }

    enum ColorRole {
        static let backgroundTop = Color.clear
        static let backgroundBottom = Color.clear
        static let glowWarm = Color.white
        static let glowCool = Color.white
        static let shellTintTop = Color.white.opacity(Opacity.shellTint)
        static let shellTintBottom = Color.white.opacity(0.06)
        static let shellHighlight = Color.white.opacity(Opacity.shellGlow)
        static let shellBorder = Color.white.opacity(0.34)
        static let cardBackgroundTop = Color.white.opacity(Opacity.glassTop)
        static let cardBackgroundBottom = Color.white.opacity(Opacity.glassBottom)
        static let cardBackground = Color.white.opacity(0.24)
        static let primaryText = Color(red: 0.16, green: 0.20, blue: 0.27)
        static let secondaryText = Color(red: 0.16, green: 0.20, blue: 0.27).opacity(Opacity.textSecondary)
        static let tertiaryText = Color(red: 0.16, green: 0.20, blue: 0.27).opacity(Opacity.textTertiary)
        static let accent = Color(red: 0.16, green: 0.20, blue: 0.27)
        static let dueDate = Color(red: 0.27, green: 0.53, blue: 0.92)
        static let danger = Color(red: 0.94, green: 0.36, blue: 0.42)
        static let successMuted = Color(red: 0.16, green: 0.20, blue: 0.27).opacity(0.92)
        static let warning = Color(red: 0.98, green: 0.76, blue: 0.08)
        static let warningHover = Color(red: 1.0, green: 0.82, blue: 0.18)
        static let dueDateUrgentTag = Color(red: 0.18, green: 0.21, blue: 0.26)
        static let dueDateSoonTag = Color(red: 0.31, green: 0.35, blue: 0.41)
        static let dueDateUpcomingTag = Color(red: 0.44, green: 0.49, blue: 0.56)
        static let dueDateNeutralText = Color.white
        static let removeDate = Color(red: 0.84, green: 0.30, blue: 0.32)
        static let removeDateHover = Color(red: 0.72, green: 0.20, blue: 0.24)
        static let calendarHover = Color.black.opacity(0.05)
        static let calendarTodayStroke = Color.black.opacity(0.14)
        static let rowHover = Color.white.opacity(Opacity.rowHoverFill)
        static let inputBackground = Color.white.opacity(Opacity.inputFill)
        static let footerBackground = Color.white.opacity(0.22)
        static let cardBorder = Color.white.opacity(Stroke.cardOpacity)
        static let resizeHover = Color.white.opacity(Opacity.resizeHoverFill)
        static let editPanelBackground = Color.white.opacity(0.24)
        static let emojiPlateBackground = Color.white.opacity(0.26)
        static let pillBackground = Color.white.opacity(0.42)
        static let stripe = Color.white.opacity(Opacity.stripe)
        static let headerRule = Color.black.opacity(0.18)
    }
}
