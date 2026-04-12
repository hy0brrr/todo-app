import SwiftUI

struct PartitionEditView: View {
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
        VStack(spacing: DesignTokens.Spacing.cardHeaderRuleGap) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.cardHeaderGap) {
                TextField(
                    "",
                    text: $editName,
                    prompt: Text("Partition Name")
                        .foregroundStyle(DesignTokens.ColorRole.tertiaryText)
                )
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.captionStrong)
                .padding(.horizontal, DesignTokens.Spacing.inputHorizontal)
                .frame(height: DesignTokens.Size.trailingControl)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
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
                        .font(DesignTokens.Typography.icon)
                        .foregroundStyle(DesignTokens.ColorRole.primaryText)
                        .frame(
                            width: DesignTokens.Size.trailingControl,
                            height: DesignTokens.Size.trailingControl
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, DesignTokens.Spacing.partitionHeaderContentLeadingInset)
            .frame(height: DesignTokens.Size.trailingControl, alignment: .leading)

            Rectangle()
                .fill(DesignTokens.ColorRole.headerRule)
                .frame(height: DesignTokens.Stroke.headerRuleLineWidth)
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.top, DesignTokens.Spacing.cardHeaderTop)
        .padding(.bottom, DesignTokens.Spacing.cardHeaderBottom)
        .background(DesignTokens.ColorRole.editPanelBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            isNameFocused = true
        }
    }
}
