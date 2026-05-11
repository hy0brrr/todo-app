import SwiftUI

struct TaskEditorPopover: View {
    @Environment(\.interfaceDensity) private var density

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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.scaledEditorSectionGap(in: density)) {
            Text(title)
                .font(DesignTokens.Typography.captionStrong(in: density))
                .foregroundStyle(DesignTokens.ColorRole.primaryText)

            TextField("Task name [tag]", text: $text)
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body(in: density))
                .padding(.horizontal, DesignTokens.Spacing.scaledInputHorizontal(in: density))
                .padding(.vertical, DesignTokens.Spacing.scaledInputVertical(in: density))
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledField(in: density), style: .continuous)
                        .fill(DesignTokens.ColorRole.inputBackground)
                )
                .onSubmit(save)

            Text("Use [tag] to create tags inline.")
                .font(DesignTokens.Typography.micro(in: density))
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(DesignTokens.Typography.caption(in: density))
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)

                Button(saveLabel) {
                    save()
                }
                .buttonStyle(.plain)
                .font(DesignTokens.Typography.captionStrong(in: density))
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
            }
        }
        .padding(DesignTokens.scaled(16, in: density))
        .frame(width: DesignTokens.Size.scaledTaskEditorWidth(in: density))
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
    @Environment(\.interfaceDensity) private var density

    let text: String
    let style: TaskTagChipStyle

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.dueDateTag(in: density))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DesignTokens.Spacing.scaledDueDateTagHorizontal(in: density))
            .padding(.vertical, DesignTokens.Spacing.scaledDueDateTagVertical(in: density))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledDueDateTag(in: density), style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledDueDateTag(in: density), style: .continuous)
                    .strokeBorder(borderColor, lineWidth: DesignTokens.Stroke.scaledDueDateOutlineLineWidth(in: density))
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
