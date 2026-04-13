import SwiftUI
import AppKit

private final class InlineEditingTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard let editor = currentEditor() else {
            return super.performKeyEquivalent(with: event)
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == [.command], let characters = event.charactersIgnoringModifiers?.lowercased() else {
            return super.performKeyEquivalent(with: event)
        }

        switch characters {
        case "x":
            NSApp.sendAction(#selector(NSText.cut(_:)), to: editor, from: self)
            return true
        case "c":
            NSApp.sendAction(#selector(NSText.copy(_:)), to: editor, from: self)
            return true
        case "v":
            NSApp.sendAction(#selector(NSText.paste(_:)), to: editor, from: self)
            return true
        case "a":
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: editor, from: self)
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

private struct InlinePartitionTitleEditor: NSViewRepresentable {
    @Binding var text: String
    let isEditing: Bool
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit, onCancel: onCancel)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = InlineEditingTextField(frame: .zero)
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        configure(textField)
        textField.stringValue = text

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        configure(nsView)

        if nsView.currentEditor() == nil, nsView.stringValue != text {
            nsView.stringValue = text
        }

        if isEditing, !context.coordinator.wasEditing {
            context.coordinator.wasEditing = true
            context.coordinator.beginEditingSession()
            DispatchQueue.main.async {
                guard nsView.window != nil else { return }
                nsView.window?.makeFirstResponder(nsView)
                nsView.selectText(nil)
                nsView.currentEditor()?.selectAll(nil)
            }
        } else if !isEditing, context.coordinator.wasEditing {
            context.coordinator.wasEditing = false
            if nsView.window?.firstResponder === nsView.currentEditor() {
                nsView.window?.makeFirstResponder(nil)
            }
        }
    }

    private func configure(_ textField: NSTextField) {
        textField.isEditable = isEditing
        textField.isSelectable = isEditing
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.backgroundColor = .clear
        textField.textColor = NSColor(DesignTokens.ColorRole.primaryText)
        textField.font = partitionTitleNSFont
        textField.alignment = .left
        textField.lineBreakMode = .byTruncatingTail
        textField.isHidden = !isEditing
        textField.maximumNumberOfLines = 1
        textField.usesSingleLineMode = true
        textField.cell?.font = partitionTitleNSFont
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.cell?.usesSingleLineMode = true
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private var partitionTitleNSFont: NSFont {
        if let customFont = NSFont(name: "PPNeueMontrealVariable-SemiBold", size: 16) {
            return customFont
        }

        return .systemFont(ofSize: 16, weight: .bold)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        let onCommit: () -> Void
        let onCancel: () -> Void
        weak var textField: NSTextField?
        var wasEditing = false
        private var didBeginEditing = false
        private var didCommitFromCommand = false
        private var didCancelFromCommand = false

        init(text: Binding<String>, onCommit: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self._text = text
            self.onCommit = onCommit
            self.onCancel = onCancel
        }

        func beginEditingSession() {
            didBeginEditing = false
            didCommitFromCommand = false
            didCancelFromCommand = false
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            didBeginEditing = true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue

            defer {
                didBeginEditing = false
                didCommitFromCommand = false
                didCancelFromCommand = false
            }

            guard EditingLayerInteractivity.shouldCommitOnEndEditing(
                didBeginEditing: didBeginEditing,
                didCommitFromCommand: didCommitFromCommand,
                didCancelFromCommand: didCancelFromCommand
            ) else { return }
            onCommit()
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                text = textView.string
                didCommitFromCommand = true
                onCommit()
                return true
            }

            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                didCancelFromCommand = true
                onCancel()
                return true
            }

            return false
        }
    }
}

struct PartitionView: View {
    let partition: Partition
    let taskGroups: [ActiveTaskGroup]
    let isEditing: Bool
    let onAddTask: (String, String) -> Void
    let onAddChildTask: (String, String) -> Void
    let onToggleComplete: (String) -> Void
    let onToggleStar: (String) -> Void
    let onSetDueDate: (String, Date?) -> Void
    let onSaveTask: (String, String) -> Void
    let onSaveEdit: (String) -> Void

    @State private var newTaskName: String = ""
    @State private var isEditingTitle = false
    @State private var editingTitle = ""
    @State private var childDraftParentTaskId: String?
    @State private var childDraftText: String = ""
    @FocusState private var focusedChildDraftParentTaskId: String?

    var body: some View {
        VStack(spacing: 0) {
            partitionHeader

            // Task list
            ScrollView {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(taskGroups) { group in
                            let childRows = ChildTaskOrdering.orderedRows(
                                for: group.children,
                                parentTaskId: group.rootTask.id,
                                showInlineDraft: childDraftParentTaskId == group.rootTask.id
                            )

                            TaskItemView(
                                task: group.rootTask,
                                depth: 0,
                                renderMode: .active,
                                onSaveTask: onSaveTask,
                                onBeginAddChildTask: beginInlineChildTaskCreation,
                                onToggleComplete: onToggleComplete,
                                onToggleStar: onToggleStar,
                                onSetDueDate: onSetDueDate
                            )

                            ForEach(childRows) { row in
                                switch row {
                                case .child(let child):
                                    TaskItemView(
                                        task: child,
                                        depth: 1,
                                        renderMode: .active,
                                        onSaveTask: onSaveTask,
                                        onBeginAddChildTask: beginInlineChildTaskCreation,
                                        onToggleComplete: onToggleComplete,
                                        onToggleStar: onToggleStar,
                                        onSetDueDate: onSetDueDate
                                    )
                                case .inlineDraft(let parentTaskId):
                                    inlineChildDraftRow(parentTaskId: parentTaskId)
                                }
                            }
                        }
                    }

                    if taskGroups.isEmpty {
                        Text("No tasks yet.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                            .italic()
                            .padding(.horizontal, DesignTokens.Spacing.listEmptyHorizontal)
                            .padding(.vertical, DesignTokens.Spacing.listEmptyVertical)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, DesignTokens.Spacing.sectionBodyTop)
            }

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Add task input
            addTaskBar
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay {
            if #unavailable(macOS 26.0) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.cardLineWidth)
            }
        }
        .shadow(
            color: .black.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            y: DesignTokens.Shadow.cardYOffset
        )
        .onAppear {
            if isEditing {
                beginTitleEditing()
            }
        }
        .onChange(of: isEditing) { _, newValue in
            guard newValue else { return }
            beginTitleEditing()
        }
        .onChange(of: focusedChildDraftParentTaskId) { oldValue, newValue in
            guard oldValue != nil, newValue == nil else { return }
            finalizeInlineChildTaskCreation()
        }
    }

    private var partitionHeader: some View {
        VStack(spacing: DesignTokens.Spacing.cardHeaderRuleGap) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.cardHeaderGap) {
                partitionTitleContent
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, DesignTokens.Spacing.partitionHeaderContentLeadingInset)

            headerRule
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.top, DesignTokens.Spacing.cardHeaderTop)
        .padding(.bottom, DesignTokens.Spacing.cardHeaderBottom)
    }

    private var headerRule: some View {
        Rectangle()
            .fill(DesignTokens.ColorRole.headerRule)
            .frame(height: DesignTokens.Stroke.headerRuleLineWidth)
    }

    private var partitionTitleContent: some View {
        HStack(spacing: DesignTokens.Spacing.partitionTitleInlineGap) {
            PartitionTitleIcon()
                .frame(height: DesignTokens.Size.partitionTitleRowHeight)
                .offset(x: DesignTokens.Spacing.partitionTitleIconOpticalOffsetX)
            ZStack(alignment: .leading) {
                Text(partition.name.isEmpty ? "Untitled" : partition.name)
                    .font(DesignTokens.Typography.partitionHeaderTitle)
                    .foregroundStyle(DesignTokens.ColorRole.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .opacity(isEditingTitle ? 0 : 1)
                    .allowsHitTesting(EditingLayerInteractivity.shouldAllowStaticDisplayHitTesting(isEditing: isEditingTitle))
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        beginTitleEditing()
                    }

                InlinePartitionTitleEditor(
                    text: $editingTitle,
                    isEditing: isEditingTitle,
                    onCommit: commitTitleEdit,
                    onCancel: cancelTitleEdit
                )
            }
            .frame(height: DesignTokens.Size.partitionTitleRowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: DesignTokens.Size.partitionTitleRowHeight, alignment: .center)
    }

    private var addTaskBar: some View {
        HStack(spacing: DesignTokens.Spacing.taskLeadingGap) {
            Image(systemName: "plus")
                .font(DesignTokens.Typography.icon)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .frame(
                    width: DesignTokens.Size.checkboxTapTarget,
                    height: DesignTokens.Size.checkboxTapTarget
                )
                .offset(x: DesignTokens.Spacing.addTaskPlusOpticalOffsetX)

            TextField(
                "",
                text: $newTaskName,
                prompt: Text("Add task to \(partition.name.isEmpty ? "Untitled" : partition.name) with [tag]")
                    .foregroundStyle(DesignTokens.ColorRole.tertiaryText)
            )
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .onSubmit {
                    let trimmed = newTaskName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onAddTask(partition.id, trimmed)
                    newTaskName = ""
                }
        }
        .padding(.horizontal, DesignTokens.Spacing.sectionPaddingHorizontal)
        .padding(.vertical, 6)
        .background(DesignTokens.ColorRole.footerBackground)
    }

    @ViewBuilder
    private func inlineChildDraftRow(parentTaskId: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.taskLeadingGap) {
            Image(systemName: "plus")
                .font(DesignTokens.Typography.icon)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .frame(
                    width: DesignTokens.Size.checkboxTapTarget,
                    height: DesignTokens.Size.checkboxTapTarget
                )
                .padding(.leading, checkboxAlignedLeadingInset)
                .frame(width: leadingControlWidth, height: DesignTokens.Size.checkboxTapTarget, alignment: .leading)
                .offset(x: DesignTokens.Spacing.addTaskPlusOpticalOffsetX)

            TextField("", text: $childDraftText, prompt: Text("Add subtask with [tag]")
                .foregroundStyle(DesignTokens.ColorRole.tertiaryText))
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .focused($focusedChildDraftParentTaskId, equals: parentTaskId)
                .onSubmit {
                    createInlineChildTask()
                }
        }
        .padding(.leading, DesignTokens.Spacing.childTaskIndent)
        .padding(.horizontal, DesignTokens.Spacing.rowHorizontal)
        .padding(.vertical, DesignTokens.Spacing.rowVertical)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.row, style: .continuous)
                .fill(Color.clear)
        )
        .onAppear {
            DispatchQueue.main.async {
                focusedChildDraftParentTaskId = parentTaskId
            }
        }
    }

    private var cardBackground: some View {
        let cardShape = RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)

        return ZStack {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: cardShape)
                    .environment(\.appearsActive, true)

                cardShape
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.cardLineWidth)
            } else {
                ZStack {
                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.ColorRole.cardBackgroundTop,
                                    DesignTokens.ColorRole.cardBackgroundBottom
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    cardShape
                        .fill(Color.white.opacity(0.08))

                    cardShape
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }

    private func beginTitleEditing() {
        editingTitle = partition.name
        isEditingTitle = true
    }

    private func beginInlineChildTaskCreation(parentTaskId: String) {
        childDraftParentTaskId = parentTaskId
        childDraftText = ""
        DispatchQueue.main.async {
            focusedChildDraftParentTaskId = parentTaskId
        }
    }

    private func createInlineChildTask() {
        guard let parentTaskId = childDraftParentTaskId else { return }
        let trimmed = childDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetInlineChildDraft()
            return
        }

        onAddChildTask(parentTaskId, trimmed)
        resetInlineChildDraft()
    }

    private func finalizeInlineChildTaskCreation() {
        let trimmed = childDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetInlineChildDraft()
            return
        }

        createInlineChildTask()
    }

    private func resetInlineChildDraft() {
        childDraftParentTaskId = nil
        childDraftText = ""
        focusedChildDraftParentTaskId = nil
    }

    private func commitTitleEdit() {
        isEditingTitle = false

        let trimmed = editingTitle.trimmingCharacters(in: .whitespaces)
        onSaveEdit(trimmed.isEmpty ? "Untitled" : trimmed)
    }

    private func cancelTitleEdit() {
        isEditingTitle = false

        if isEditing {
            onSaveEdit(partition.name.isEmpty ? "Untitled" : partition.name)
        }
    }

    private var leadingControlWidth: CGFloat {
        return max(
            checkboxAlignedLeadingInset + DesignTokens.Size.checkboxTapTarget,
            DesignTokens.Size.starMarkerTapTargetWidth
        )
    }

    private var checkboxAlignedLeadingInset: CGFloat {
        let checkboxVisualInset = (DesignTokens.Size.checkboxTapTarget - DesignTokens.Size.checkbox) / 2
        return DesignTokens.Spacing.sectionPaddingHorizontal
            + DesignTokens.Spacing.partitionHeaderContentLeadingInset
            - DesignTokens.Spacing.rowHorizontal
            - checkboxVisualInset
    }
}

// MARK: - Preview

#Preview {
    PartitionView(
        partition: Partition(name: "Work", color: .blue),
        taskGroups: [
            ActiveTaskGroup(
                rootTask: TodoTask(partitionId: "p1", name: "整理第二季度产品需求", tags: ["Strategy"], isStarred: true),
                children: [TodoTask(partitionId: "p1", name: "补齐竞品调研", parentTaskId: "root")]
            ),
            ActiveTaskGroup(
                rootTask: TodoTask(partitionId: "p1", name: "更新路线图", tags: ["Planning"], dueDate: Date()),
                children: []
            )
        ],
        isEditing: false,
        onAddTask: { _, _ in },
        onAddChildTask: { _, _ in },
        onToggleComplete: { _ in },
        onToggleStar: { _ in },
        onSetDueDate: { _, _ in },
        onSaveTask: { _, _ in },
        onSaveEdit: { _ in }
    )
    .frame(width: 350, height: 250)
    .padding()
}
