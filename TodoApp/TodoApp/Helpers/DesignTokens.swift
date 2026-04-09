import SwiftUI
import AppKit

enum DesignTokens {
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
        static let checkboxTitleOverhang: CGFloat = 2
        static let starMarkerLeadingOffset: CGFloat = -7
        static let dueDateTagHorizontal: CGFloat = 7
        static let dueDateTagVertical: CGFloat = 2
        static let starMarkerPreviewOpacity: Double = 0.72
        static let inputHorizontal: CGFloat = 8
        static let inputVertical: CGFloat = 6
        static let modalHorizontal: CGFloat = 16
        static let modalHeaderVertical: CGFloat = 12
        static let modalFooterVertical: CGFloat = 10
        static let modalListRowVertical: CGFloat = 3
        static let cardHeaderGap: CGFloat = 12
        static let cardTitleGap: CGFloat = 4
        static let partitionTitleInlineGap: CGFloat = 8
        static let partitionHeaderContentLeadingInset: CGFloat = 4
    }

    enum Radius {
        static let card: CGFloat = 14
        static let row: CGFloat = 8
        static let field: CGFloat = 7
        static let checkbox: CGFloat = 4
        static let pill: CGFloat = 8
        static let titleTag: CGFloat = 6
        static let dueDateTag: CGFloat = 5
        static let starMarker: CGFloat = 2
        static let emojiPlate: CGFloat = 12
    }

    enum Stroke {
        static let cardLineWidth: CGFloat = 1
        static let checkboxLineWidth: CGFloat = 1.5
        static let dueDateOutlineLineWidth: CGFloat = 0.8
        static let headerRuleLineWidth: CGFloat = 0.5
        static let cardOpacity: Double = 0.48
        static let dividerOpacity: Double = 0.10
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

        static var screenTitle: Font { appFont(size: 30, role: .semibold, fallbackWeight: .semibold) }
        static var screenSubtitle: Font { appFont(size: 14, role: .medium, fallbackWeight: .medium) }
        static var partitionHeader: Font { appFont(size: 12, role: .semibold, fallbackWeight: .semibold) }
        static var partitionHeaderTitle: Font { titleFont(size: 16, fallbackWeight: .bold) }
        static var partitionMeta: Font { appFont(size: 12, role: .medium, fallbackWeight: .medium) }
        static let partitionHeaderTracking: CGFloat = 0
        static var body: Font { appFont(size: 15, role: .regular, fallbackWeight: .regular) }
        static var modalTitle: Font { appFont(size: 15, role: .bold, fallbackWeight: .bold) }
        static var bodyMedium: Font { appFont(size: 14, role: .medium, fallbackWeight: .medium) }
        static var caption: Font { appFont(size: 13, role: .medium, fallbackWeight: .medium) }
        static var captionStrong: Font { appFont(size: 13, role: .bold, fallbackWeight: .bold) }
        static var micro: Font { appFont(size: 12, role: .medium, fallbackWeight: .medium) }
        static var dueDateTag: Font { appFont(size: 11, role: .regular, fallbackWeight: .regular) }
        static var icon: Font { appFont(size: 12, role: .semibold, fallbackWeight: .semibold) }
        static var star: Font { appFont(size: 13, role: .medium, fallbackWeight: .medium) }
        static var checkmark: Font { appFont(size: 8, role: .bold, fallbackWeight: .bold, design: .default) }
        static var emoji: Font { appFont(size: 38, role: .regular, fallbackWeight: .regular, design: .default) }
    }

    enum Size {
        static let partitionIndicator: CGFloat = 8
        static let checkbox: CGFloat = 14
        static let checkboxTapTarget: CGFloat = 24
        static let starMarkerWidth: CGFloat = 3
        static let starMarkerHeight: CGFloat = 18
        static let starMarkerTapTargetWidth: CGFloat = 12
        static let trailingControl: CGFloat = 24
        static let dueDateColumnMinWidth: CGFloat = 108
        static let partitionColorDot: CGFloat = 14
        static let modalPartitionDot: CGFloat = 10
        static let resizeHandleHeight: CGFloat = 6
        static let partitionMinHeight: CGFloat = 200
        static let completedMinHeight: CGFloat = 200
        static let modalWidth: CGFloat = 330
        static let modalMinHeight: CGFloat = 300
        static let modalMaxHeight: CGFloat = 500
        static let appMinWidth: CGFloat = 300
        static let appIdealWidth: CGFloat = 380
        static let appMaxWidth: CGFloat = .infinity
        static let appMinHeight: CGFloat = 560
        static let datePopoverWidth: CGFloat = 280
        static let emojiPlate: CGFloat = 48
        static let partitionTitleIcon: CGFloat = 12
        static let partitionTitleIconStroke: CGFloat = 2.6
        static let topGlow: CGFloat = 280
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
