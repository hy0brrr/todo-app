import SwiftUI
import AppKit

enum EmptyTodoPlaceholderLayout {
    static let fixedArtworkSide: CGFloat = 80

    static func imageSide(for _: CGSize) -> CGFloat {
        fixedArtworkSide
    }
}

struct EmptyTodoPlaceholderView: View {
    var body: some View {
        GeometryReader { geometry in
            let imageSide = EmptyTodoPlaceholderLayout.imageSide(for: geometry.size)

            if imageSide > 0 {
                EmptyTodoIllustration()
                    .frame(width: imageSide, height: imageSide)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}

private struct EmptyTodoIllustration: View {
    private static let image: NSImage? = {
        guard let url = Bundle.main.url(forResource: "empty-todo", withExtension: "svg") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }()

    var body: some View {
        Group {
            if let image = Self.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

enum TextEditingCommandAction: Equatable {
    case selector(Selector)
    case undo
    case redo
}

enum TextEditingCommandBridge {
    static func action(
        forCharactersIgnoringModifiers characters: String?,
        modifierFlags: NSEvent.ModifierFlags
    ) -> TextEditingCommandAction? {
        let flags = modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let character = characters?.lowercased() else {
            return nil
        }

        if flags == [.command] {
            switch character {
            case "x":
                return .selector(#selector(NSText.cut(_:)))
            case "c":
                return .selector(#selector(NSText.copy(_:)))
            case "v":
                return .selector(#selector(NSText.paste(_:)))
            case "a":
                return .selector(#selector(NSText.selectAll(_:)))
            case "z":
                return .undo
            default:
                return nil
            }
        }

        if flags == [.command, .shift], character == "z" {
            return .redo
        }

        return nil
    }

    static func selector(
        forCharactersIgnoringModifiers characters: String?,
        modifierFlags: NSEvent.ModifierFlags
    ) -> Selector? {
        guard case .selector(let selector) = action(
            forCharactersIgnoringModifiers: characters,
            modifierFlags: modifierFlags
        ) else {
            return nil
        }

        return selector
    }

    static func performKeyEquivalent(_ event: NSEvent, in textField: NSTextField) -> Bool {
        guard
            let editor = textField.currentEditor(),
            let action = action(
                forCharactersIgnoringModifiers: event.charactersIgnoringModifiers,
                modifierFlags: event.modifierFlags
            )
        else {
            return false
        }

        switch action {
        case .selector(let selector):
            NSApp.sendAction(selector, to: editor, from: textField)
            return true
        case .undo:
            undoManager(for: editor)?.undo()
            return true
        case .redo:
            undoManager(for: editor)?.redo()
            return true
        }
    }

    private static func undoManager(for editor: NSText) -> UndoManager? {
        if let textView = editor as? NSTextView {
            return textView.undoManager ?? textView.window?.undoManager
        }

        return editor.undoManager
    }
}

enum DraftTaskInputCommandAction: Equatable {
    case submit
    case cancel
    case unhandled
}

enum DraftTaskInputCommandHandling {
    static func action(for commandSelector: Selector) -> DraftTaskInputCommandAction {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            return .submit
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            return .cancel
        }

        return .unhandled
    }
}

enum AddTaskInputSynchronization {
    static func textFieldValueToApply(
        displayedText: String,
        bindingText: String,
        isEditing: Bool
    ) -> String? {
        guard displayedText != bindingText else { return nil }
        guard !isEditing || bindingText.isEmpty else { return nil }
        return bindingText
    }
}

private final class InlineEditingTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if TextEditingCommandBridge.performKeyEquivalent(event, in: self) {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}

private final class AddTaskTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if TextEditingCommandBridge.performKeyEquivalent(event, in: self) {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}

private struct AddTaskInputField: NSViewRepresentable {
    @Binding var text: String
    let prompt: String
    let density: InterfaceDensity
    let onSubmit: () -> Void
    var focusOnAppear: Bool = false
    var onCancel: (() -> Void)?
    var onEndEditing: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSubmit: onSubmit,
            onCancel: onCancel,
            onEndEditing: onEndEditing
        )
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = AddTaskTextField(frame: .zero)
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        configure(textField)
        textField.stringValue = text
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        configure(nsView)
        let editor = nsView.currentEditor()
        let displayedText = editor?.string ?? nsView.stringValue
        if let value = AddTaskInputSynchronization.textFieldValueToApply(
            displayedText: displayedText,
            bindingText: text,
            isEditing: editor != nil
        ) {
            nsView.stringValue = value
            editor?.string = value
        }

        if focusOnAppear, nsView.currentEditor() == nil {
            DispatchQueue.main.async {
                guard nsView.window != nil else { return }
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    private func configure(_ textField: NSTextField) {
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.backgroundColor = .clear
        textField.textColor = NSColor(DesignTokens.ColorRole.primaryText)
        textField.placeholderString = prompt
        textField.font = taskDraftNSFont
        textField.alignment = .left
        textField.lineBreakMode = .byTruncatingTail
        textField.maximumNumberOfLines = 1
        textField.usesSingleLineMode = true
        textField.cell?.font = taskDraftNSFont
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.cell?.usesSingleLineMode = true
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private var taskDraftNSFont: NSFont {
        let fontSize = DesignTokens.Typography.bodySize(in: density)
        if let customFont = NSFont(name: "PingFangSC-Regular", size: fontSize) {
            return customFont
        }

        return .systemFont(ofSize: fontSize, weight: .regular)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        let onSubmit: () -> Void
        let onCancel: (() -> Void)?
        let onEndEditing: (() -> Void)?
        weak var textField: NSTextField?
        private var didFinishFromCommand = false

        init(
            text: Binding<String>,
            onSubmit: @escaping () -> Void,
            onCancel: (() -> Void)?,
            onEndEditing: (() -> Void)?
        ) {
            self._text = text
            self.onSubmit = onSubmit
            self.onCancel = onCancel
            self.onEndEditing = onEndEditing
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            ((obj.object as? NSTextField)?.currentEditor() as? NSTextView)?.allowsUndo = true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue

            defer {
                didFinishFromCommand = false
            }

            guard !didFinishFromCommand else { return }
            onEndEditing?()
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch DraftTaskInputCommandHandling.action(for: commandSelector) {
            case .submit:
                didFinishFromCommand = true
                text = textView.string
                onSubmit()
                if text.isEmpty {
                    textView.string = ""
                    (control as? NSTextField)?.stringValue = ""
                }
                return true

            case .cancel:
                guard let onCancel else { return false }
                didFinishFromCommand = true
                text = ""
                textView.string = ""
                (control as? NSTextField)?.stringValue = ""
                onCancel()
                return true

            case .unhandled:
                return false
            }
        }
    }
}

private struct InlinePartitionTitleEditor: NSViewRepresentable {
    @Binding var text: String
    let density: InterfaceDensity
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
        let fontSize = DesignTokens.Typography.partitionHeaderTitleSize(in: density)
        if let customFont = NSFont(name: "PPNeueMontrealVariable-SemiBold", size: fontSize) {
            return customFont
        }

        return .systemFont(ofSize: fontSize, weight: .bold)
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
    @Environment(\.interfaceDensity) private var density

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
            if taskGroups.isEmpty {
                EmptyTodoPlaceholderView()
            } else {
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
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, DesignTokens.Spacing.scaledSectionBodyTop(in: density))
                }
            }

            Divider().opacity(DesignTokens.Stroke.dividerOpacity)

            // Add task input
            addTaskBar
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous))
        .overlay {
            if #unavailable(macOS 26.0) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous)
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.scaledCardLineWidth(in: density))
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
        VStack(spacing: DesignTokens.Spacing.scaledCardHeaderRuleGap(in: density)) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.scaledCardHeaderGap(in: density)) {
                partitionTitleContent
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density))

            headerRule
        }
        .padding(.horizontal, DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density))
        .padding(.top, DesignTokens.Spacing.scaledCardHeaderTop(in: density))
        .padding(.bottom, DesignTokens.Spacing.scaledCardHeaderBottom(in: density))
    }

    private var headerRule: some View {
        Rectangle()
            .fill(DesignTokens.ColorRole.headerRule)
            .frame(height: DesignTokens.Stroke.scaledHeaderRuleLineWidth(in: density))
    }

    private var partitionTitleContent: some View {
        HStack(spacing: DesignTokens.Spacing.scaledPartitionTitleInlineGap(in: density)) {
            PartitionTitleIcon()
                .frame(height: DesignTokens.Size.scaledPartitionTitleRowHeight(in: density))
                .offset(x: DesignTokens.Spacing.partitionTitleIconOpticalOffsetX)
            ZStack(alignment: .leading) {
                Text(partition.name.isEmpty ? "Untitled" : partition.name)
                    .font(DesignTokens.Typography.partitionHeaderTitle(in: density))
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
                    density: density,
                    isEditing: isEditingTitle,
                    onCommit: commitTitleEdit,
                    onCancel: cancelTitleEdit
                )
            }
            .frame(height: DesignTokens.Size.scaledPartitionTitleRowHeight(in: density))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: DesignTokens.Size.scaledPartitionTitleRowHeight(in: density), alignment: .center)
    }

    private var addTaskBar: some View {
        HStack(spacing: DesignTokens.Spacing.scaledTaskLeadingGap(in: density)) {
            Image(systemName: "plus")
                .font(DesignTokens.Typography.icon(in: density))
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .frame(
                    width: DesignTokens.Size.scaledCheckboxTapTarget(in: density),
                    height: DesignTokens.Size.scaledCheckboxTapTarget(in: density)
                )
                .offset(x: DesignTokens.Spacing.addTaskPlusOpticalOffsetX)

            AddTaskInputField(
                text: $newTaskName,
                prompt: "Add task to \(partition.name.isEmpty ? "Untitled" : partition.name) with [tag]",
                density: density,
                onSubmit: submitNewTask
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density))
        .padding(.vertical, DesignTokens.scaled(6, in: density))
        .background(DesignTokens.ColorRole.footerBackground)
    }

    @ViewBuilder
    private func inlineChildDraftRow(parentTaskId: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.scaledTaskLeadingGap(in: density)) {
            Image(systemName: "plus")
                .font(DesignTokens.Typography.icon(in: density))
                .foregroundStyle(DesignTokens.ColorRole.primaryText)
                .frame(
                    width: DesignTokens.Size.scaledCheckboxTapTarget(in: density),
                    height: DesignTokens.Size.scaledCheckboxTapTarget(in: density)
                )
                .padding(.leading, checkboxAlignedLeadingInset)
                .frame(width: leadingControlWidth, height: DesignTokens.Size.scaledCheckboxTapTarget(in: density), alignment: .leading)
                .offset(x: DesignTokens.Spacing.addTaskPlusOpticalOffsetX)

            AddTaskInputField(
                text: $childDraftText,
                prompt: "Add subtask with [tag]",
                density: density,
                onSubmit: createInlineChildTask,
                focusOnAppear: childDraftParentTaskId == parentTaskId,
                onCancel: resetInlineChildDraft,
                onEndEditing: finalizeInlineChildTaskCreation
            )
        }
        .padding(.leading, DesignTokens.Spacing.scaledChildTaskIndent(in: density))
        .padding(.horizontal, DesignTokens.Spacing.scaledRowHorizontal(in: density))
        .padding(.vertical, DesignTokens.Spacing.scaledRowVertical(in: density))
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledRow(in: density), style: .continuous)
                .fill(Color.clear)
        )
        .onAppear {
            DispatchQueue.main.async {
                focusedChildDraftParentTaskId = parentTaskId
            }
        }
    }

    private var cardBackground: some View {
        let cardShape = RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous)

        return ZStack {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: cardShape)
                    .environment(\.appearsActive, true)

                cardShape
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.scaledCardLineWidth(in: density))
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

    private func submitNewTask() {
        let trimmed = newTaskName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onAddTask(partition.id, trimmed)
        newTaskName = ""
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
            checkboxAlignedLeadingInset + DesignTokens.Size.scaledCheckboxTapTarget(in: density),
            DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: density)
        )
    }

    private var checkboxAlignedLeadingInset: CGFloat {
        let checkboxVisualInset = (DesignTokens.Size.scaledCheckboxTapTarget(in: density) - DesignTokens.Size.scaledCheckbox(in: density)) / 2
        return DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density)
            + DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density)
            - DesignTokens.Spacing.scaledRowHorizontal(in: density)
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
