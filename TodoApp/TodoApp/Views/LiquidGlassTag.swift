import SwiftUI

struct LiquidGlassTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.partitionHeader)
            .foregroundStyle(DesignTokens.ColorRole.primaryText)
            .padding(.horizontal, DesignTokens.Spacing.titlePillHorizontal)
            .padding(.vertical, DesignTokens.Spacing.titlePillVertical)
            .background(tagBackground)
    }

    @ViewBuilder
    private var tagBackground: some View {
        let tagShape = RoundedRectangle(cornerRadius: DesignTokens.Radius.titleTag, style: .continuous)

        if #available(macOS 26.0, *) {
            ZStack {
                Color.clear
                    .glassEffect(.regular, in: tagShape)
                    .environment(\.appearsActive, true)

                tagShape
                    .fill(Color.white.opacity(0.04))

                tagShape
                    .strokeBorder(Color.white.opacity(0.52), lineWidth: 1)
            }
        } else {
            tagShape
                .fill(DesignTokens.ColorRole.pillBackground)
                .overlay(
                    tagShape
                        .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                )
        }
    }
}
