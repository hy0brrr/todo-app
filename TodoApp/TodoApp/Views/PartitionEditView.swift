import SwiftUI

struct PartitionEditView: View {
    @Environment(\.interfaceDensity) private var density

    let partition: Partition
    let onSave: (String) -> Void

    @State private var editName: String
    @FocusState private var isNameFocused: Bool

    init(partition: Partition, onSave: @escaping (String) -> Void) {
        self.partition = partition
        self.onSave = onSave
        _editName = State(initialValue: partition.name)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.scaledCardHeaderRuleGap(in: density)) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.scaledCardHeaderGap(in: density)) {
                TextField(
                    "",
                    text: $editName,
                    prompt: Text("Partition Name")
                        .foregroundStyle(DesignTokens.ColorRole.tertiaryText)
                )
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.captionStrong(in: density))
                .padding(.horizontal, DesignTokens.Spacing.scaledInputHorizontal(in: density))
                .frame(height: DesignTokens.Size.scaledTrailingControl(in: density))
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledField(in: density), style: .continuous)
                        .fill(DesignTokens.ColorRole.inputBackground)
                )
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .focused($isNameFocused)
                .onSubmit {
                    onSave(editName.isEmpty ? "Untitled" : editName)
                }

                Spacer(minLength: 0)

                Button {
                    onSave(editName.isEmpty ? "Untitled" : editName)
                } label: {
                    Image(systemName: "checkmark")
                        .font(DesignTokens.Typography.icon(in: density))
                        .foregroundStyle(DesignTokens.ColorRole.primaryText)
                        .frame(
                            width: DesignTokens.Size.scaledTrailingControl(in: density),
                            height: DesignTokens.Size.scaledTrailingControl(in: density)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density))
            .frame(height: DesignTokens.Size.scaledTrailingControl(in: density), alignment: .leading)

            Rectangle()
                .fill(DesignTokens.ColorRole.headerRule)
                .frame(height: DesignTokens.Stroke.scaledHeaderRuleLineWidth(in: density))
        }
        .padding(.horizontal, DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density))
        .padding(.top, DesignTokens.Spacing.scaledCardHeaderTop(in: density))
        .padding(.bottom, DesignTokens.Spacing.scaledCardHeaderBottom(in: density))
        .background(DesignTokens.ColorRole.editPanelBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            isNameFocused = true
        }
    }
}
