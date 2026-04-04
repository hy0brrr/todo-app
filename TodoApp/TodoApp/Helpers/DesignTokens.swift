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
        static let screenHeaderTop: CGFloat = 8
        static let screenHeaderBottom: CGFloat = 18
        static let windowChromeHoverHeight: CGFloat = 52
        static let windowChromeContentInset: CGFloat = 28
        static let listEmptyHorizontal: CGFloat = 16
        static let listEmptyVertical: CGFloat = 14
        static let rowHorizontal: CGFloat = 12
        static let rowVertical: CGFloat = 8
        static let inputHorizontal: CGFloat = 8
        static let inputVertical: CGFloat = 6
        static let modalHorizontal: CGFloat = 16
        static let modalHeaderVertical: CGFloat = 12
        static let modalFooterVertical: CGFloat = 10
        static let modalListRowVertical: CGFloat = 3
        static let cardHeaderGap: CGFloat = 12
        static let cardTitleGap: CGFloat = 4
        static let titlePillHorizontal: CGFloat = 10
        static let titlePillVertical: CGFloat = 5
    }

    enum Radius {
        static let card: CGFloat = 28
        static let row: CGFloat = 16
        static let field: CGFloat = 14
        static let pill: CGFloat = 999
        static let emojiPlate: CGFloat = 24
    }

    enum Stroke {
        static let cardLineWidth: CGFloat = 1
        static let checkboxLineWidth: CGFloat = 1.5
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
        static let screenTitle = Font.system(size: 30, weight: .semibold, design: .rounded)
        static let screenSubtitle = Font.system(size: 14, weight: .medium, design: .rounded)
        static let partitionHeader = Font.system(size: 26, weight: .semibold, design: .rounded)
        static let partitionMeta = Font.system(size: 12, weight: .medium, design: .rounded)
        static let partitionHeaderTracking: CGFloat = 0
        static let body = Font.system(size: 15, weight: .medium, design: .rounded)
        static let modalTitle = Font.system(size: 15, weight: .bold, design: .rounded)
        static let bodyMedium = Font.system(size: 14, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
        static let captionStrong = Font.system(size: 13, weight: .bold, design: .rounded)
        static let micro = Font.system(size: 12, weight: .medium, design: .rounded)
        static let icon = Font.system(size: 12, weight: .semibold, design: .rounded)
        static let star = Font.system(size: 13, weight: .medium, design: .rounded)
        static let checkmark = Font.system(size: 8, weight: .bold)
        static let emoji = Font.system(size: 38)
    }

    enum Size {
        static let partitionIndicator: CGFloat = 8
        static let checkbox: CGFloat = 14
        static let checkboxTapTarget: CGFloat = 24
        static let trailingControl: CGFloat = 24
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
        static let emojiPlate: CGFloat = 76
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
        static let warning = Color(red: 1.0, green: 0.93, blue: 0.55)
        static let warningHover = Color(red: 1.0, green: 0.84, blue: 0.43)
        static let rowHover = Color.white.opacity(Opacity.rowHoverFill)
        static let inputBackground = Color.white.opacity(Opacity.inputFill)
        static let footerBackground = Color.white.opacity(0.22)
        static let cardBorder = Color.white.opacity(Stroke.cardOpacity)
        static let resizeHover = Color.white.opacity(Opacity.resizeHoverFill)
        static let editPanelBackground = Color.white.opacity(0.24)
        static let emojiPlateBackground = Color.white.opacity(0.26)
        static let pillBackground = Color.white.opacity(0.42)
        static let stripe = Color.white.opacity(Opacity.stripe)
    }
}
