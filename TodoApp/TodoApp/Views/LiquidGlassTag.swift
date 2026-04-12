import SwiftUI

struct PartitionTitleIcon: View {
    var body: some View {
        ZStack {
            // Five sharp arms read closer to the reference than a rounded
            // multi-direction burst.
            ForEach([-90.0, -18.0, 54.0, 126.0, 198.0], id: \.self) { angle in
                TaperedIconArm(
                    length: DesignTokens.Size.partitionTitleIconArmLength,
                    innerThickness: DesignTokens.Size.partitionTitleIconInnerStroke,
                    outerThickness: DesignTokens.Size.partitionTitleIconOuterStroke
                )
                .fill(DesignTokens.ColorRole.primaryText)
                .frame(
                    width: DesignTokens.Size.partitionTitleIconArmLength,
                    height: DesignTokens.Size.partitionTitleIconOuterStroke
                )
                .offset(x: DesignTokens.Size.partitionTitleIconArmOffset)
                .rotationEffect(.degrees(angle))
            }
        }
        .frame(
            width: DesignTokens.Size.partitionTitleIcon,
            height: DesignTokens.Size.partitionTitleIcon
        )
    }
}

struct LiquidGlassTag: View {
    let text: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.partitionTitleInlineGap) {
            PartitionTitleIcon()

            Text(text)
                .font(DesignTokens.Typography.partitionHeaderTitle)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

private struct TaperedIconArm: Shape {
    let length: CGFloat
    let innerThickness: CGFloat
    let outerThickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let usableLength = min(length, rect.width)
        let innerHalf = innerThickness / 2
        let outerHalf = outerThickness / 2
        let centerY = rect.midY
        let startX = max(0, rect.maxX - usableLength)
        let endX = rect.maxX

        var path = Path()
        path.move(to: CGPoint(x: startX, y: centerY - innerHalf))
        path.addLine(to: CGPoint(x: endX, y: centerY - outerHalf))
        path.addLine(to: CGPoint(x: endX, y: centerY + outerHalf))
        path.addLine(to: CGPoint(x: startX, y: centerY + innerHalf))
        path.closeSubpath()
        return path
    }
}
