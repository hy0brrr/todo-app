import SwiftUI

struct PartitionEditView: View {
    let partition: Partition
    let onSave: (String, PartitionColor) -> Void

    @State private var editName: String
    @State private var editColor: PartitionColor
    @FocusState private var isNameFocused: Bool

    init(partition: Partition, onSave: @escaping (String, PartitionColor) -> Void) {
        self.partition = partition
        self.onSave = onSave
        _editName = State(initialValue: partition.name)
        _editColor = State(initialValue: partition.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                TextField(
                    "",
                    text: $editName,
                    prompt: Text("Partition Name")
                        .foregroundStyle(DesignTokens.ColorRole.tertiaryText)
                )
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.captionStrong)
                .padding(.horizontal, DesignTokens.Spacing.inputHorizontal)
                .padding(.vertical, DesignTokens.Spacing.inputVertical)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
                        .fill(DesignTokens.ColorRole.inputBackground)
                )
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .focused($isNameFocused)
                .onSubmit {
                    onSave(editName.isEmpty ? "Untitled" : editName, editColor)
                }

                Button {
                    onSave(editName.isEmpty ? "Untitled" : editName, editColor)
                } label: {
                    Image(systemName: "checkmark")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorRole.accent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                ForEach(PartitionColor.allCases, id: \.self) { c in
                    Circle()
                        .fill(c.color)
                        .frame(width: DesignTokens.Size.partitionColorDot, height: DesignTokens.Size.partitionColorDot)
                        .overlay(
                            Circle()
                                .strokeBorder(editColor == c ? DesignTokens.ColorRole.accent : Color.clear, lineWidth: 2)
                                .padding(-2)
                        )
                        .onTapGesture {
                            editColor = c
                        }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.vertical, DesignTokens.Spacing.sectionPaddingVertical)
        .background(DesignTokens.ColorRole.editPanelBackground)
        .onAppear {
            isNameFocused = true
        }
    }
}
