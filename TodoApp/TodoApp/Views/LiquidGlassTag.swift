import SwiftUI

struct LiquidGlassTag: View {
    let text: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.partitionTitleInlineGap) {
            headerIcon

            Text(text)
                .font(DesignTokens.Typography.partitionHeaderTitle)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var headerIcon: some View {
        ZStack {
            ForEach([0.0, 45.0, 90.0, 135.0], id: \.self) { angle in
                RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                    .fill(DesignTokens.ColorRole.primaryText)
                    .frame(
                        width: DesignTokens.Size.partitionTitleIcon,
                        height: DesignTokens.Size.partitionTitleIconStroke
                    )
                    .rotationEffect(.degrees(angle))
            }
        }
        .frame(
            width: DesignTokens.Size.partitionTitleIcon,
            height: DesignTokens.Size.partitionTitleIcon
        )
    }
}
