import SwiftUI

struct TaskEditorPopover: View {
    let title: String
    let saveLabel: String
    let initialText: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(
        title: String,
        saveLabel: String,
        initialText: String,
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.saveLabel = saveLabel
        self.initialText = initialText
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.editorSectionGap) {
            Text(title)
                .font(DesignTokens.Typography.captionStrong)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)

            TextField("Task name [tag]", text: $text)
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body)
                .padding(.horizontal, DesignTokens.Spacing.inputHorizontal)
                .padding(.vertical, DesignTokens.Spacing.inputVertical)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
                        .fill(DesignTokens.ColorRole.inputBackground)
                )
                .onSubmit(save)

            Text("Use [tag] to create tags inline.")
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)

                Button(saveLabel) {
                    save()
                }
                .buttonStyle(.plain)
                .font(DesignTokens.Typography.captionStrong)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
            }
        }
        .padding(16)
        .frame(width: DesignTokens.Size.taskEditorWidth)
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}

enum TaskTagChipStyle {
    case active
    case completed
}

struct TaskTagChip: View {
    let text: String
    let style: TaskTagChipStyle

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.dueDateTag)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DesignTokens.Spacing.dueDateTagHorizontal)
            .padding(.vertical, DesignTokens.Spacing.dueDateTagVertical)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.dueDateTag, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.dueDateTag, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.8)
            )
    }

    private var foregroundColor: Color {
        switch style {
        case .active:
            return DesignTokens.ColorRole.primaryText
        case .completed:
            return DesignTokens.ColorRole.secondaryText
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .active:
            return Color.white.opacity(0.52)
        case .completed:
            return Color.white.opacity(0.28)
        }
    }

    private var borderColor: Color {
        switch style {
        case .active:
            return Color.white.opacity(0.32)
        case .completed:
            return Color.white.opacity(0.16)
        }
    }
}
