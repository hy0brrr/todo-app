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

private struct InlineTaskNameEditor: NSViewRepresentable {
    @Binding var text: String
    let isEditing: Bool
    let onCommit: (String) -> Void
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
                context.coordinator.installOutsideClickMonitor()
            }
        } else if !isEditing, context.coordinator.wasEditing {
            context.coordinator.wasEditing = false
            context.coordinator.removeOutsideClickMonitor()
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
        textField.font = taskNameNSFont
        textField.alignment = .left
        textField.lineBreakMode = .byTruncatingTail
        textField.isHidden = !isEditing
        textField.maximumNumberOfLines = 1
        textField.usesSingleLineMode = true
        textField.cell?.font = taskNameNSFont
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.cell?.usesSingleLineMode = true
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private var taskNameNSFont: NSFont {
        if let customFont = NSFont(name: "PingFangSC-Regular", size: 15) {
            return customFont
        }

        return .systemFont(ofSize: 15, weight: .regular)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        let onCommit: (String) -> Void
        let onCancel: () -> Void
        weak var textField: NSTextField?
        var wasEditing = false
        private var didBeginEditing = false
        private var didCommitFromCommand = false
        private var didCancelFromCommand = false
        private var outsideClickMonitor: Any?

        init(text: Binding<String>, onCommit: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self._text = text
            self.onCommit = onCommit
            self.onCancel = onCancel
        }

        func beginEditingSession() {
            didBeginEditing = false
            didCommitFromCommand = false
            didCancelFromCommand = false
        }

        func installOutsideClickMonitor() {
            guard outsideClickMonitor == nil else { return }
            outsideClickMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                self?.commitEditingIfNeeded(for: event)
                return event
            }
        }

        func removeOutsideClickMonitor() {
            guard let outsideClickMonitor else { return }
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
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
            removeOutsideClickMonitor()

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
            onCommit(textField.stringValue)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                text = textView.string
                didCommitFromCommand = true
                onCommit(textView.string)
                return true
            }

            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                didCancelFromCommand = true
                onCancel()
                return true
            }

            return false
        }

        private func commitEditingIfNeeded(for event: NSEvent) {
            guard
                let textField,
                let window = textField.window,
                event.window === window,
                textField.currentEditor() != nil
            else { return }

            let isInsideEditorBounds = Self.isEventInsideEditorBounds(event, textField: textField)
            let hitView = Self.hitView(for: event, in: window)
            guard ClickOutsideHitTesting.shouldCommitEditingOnMouseDown(
                isEditing: true,
                isInsideEditorBounds: isInsideEditorBounds,
                hitView: hitView
            ) else { return }

            let committedText = textField.currentEditor()?.string ?? textField.stringValue
            text = committedText
            didCommitFromCommand = true
            removeOutsideClickMonitor()
            onCommit(committedText)
            window.makeFirstResponder(nil)
        }

        private static func hitView(for event: NSEvent, in window: NSWindow) -> NSView? {
            guard let contentView = window.contentView else { return nil }
            let location = contentView.convert(event.locationInWindow, from: nil)
            return contentView.hitTest(location)
        }

        private static func isEventInsideEditorBounds(_ event: NSEvent, textField: NSTextField) -> Bool {
            let location = textField.convert(event.locationInWindow, from: nil)
            return textField.bounds.contains(location)
        }

        deinit {
            removeOutsideClickMonitor()
        }
    }
}

enum TodoCursors {
    static var starMarkerAction: NSCursor {
        .pointingHand
    }
}

enum TaskItemLeadingControlLayout {
    static func checkboxLeadingInset(
        sectionPaddingHorizontal: CGFloat = DesignTokens.Spacing.sectionPaddingHorizontal,
        partitionHeaderContentLeadingInset: CGFloat = DesignTokens.Spacing.partitionHeaderContentLeadingInset,
        rowHorizontal: CGFloat = DesignTokens.Spacing.rowHorizontal,
        checkboxTapTarget: CGFloat = DesignTokens.Size.checkboxTapTarget,
        checkbox: CGFloat = DesignTokens.Size.checkbox
    ) -> CGFloat {
        let checkboxVisualInset = (checkboxTapTarget - checkbox) / 2
        return sectionPaddingHorizontal
            + partitionHeaderContentLeadingInset
            - rowHorizontal
            - checkboxVisualInset
    }

    static func starMarkerHitRegionLeadingInset(
        depth: Int,
        rowHorizontal: CGFloat = DesignTokens.Spacing.rowHorizontal,
        childTaskIndent: CGFloat = DesignTokens.Spacing.childTaskIndent,
        checkboxLeadingInset: CGFloat = checkboxLeadingInset(),
        starMarkerTapTargetWidth: CGFloat = DesignTokens.Size.starMarkerTapTargetWidth
    ) -> CGFloat {
        rowHorizontal
            + (CGFloat(depth) * childTaskIndent)
            + checkboxLeadingInset
            - starMarkerTapTargetWidth
    }
}

enum DueDateLabelLayout {
    static let textWidth: CGFloat = DesignTokens.Size.dueDateTextContentWidth
    static let textTrailingInset: CGFloat = DesignTokens.Spacing.dueDateTagHorizontal

    static var labelWidth: CGFloat {
        textWidth + (textTrailingInset * 2)
    }

    static func tagWidth(for text: String) -> CGFloat {
        textWidth(for: text) + (textTrailingInset * 2)
    }

    static func plainWidth(for text: String) -> CGFloat {
        textWidth(for: text) + textTrailingInset
    }

    private static func textWidth(for text: String) -> CGFloat {
        let font = NSFont(name: "PingFangSC-Regular", size: 11) ?? .systemFont(ofSize: 11, weight: .regular)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }
}

enum TaskRowTrailingLayout {
    static func contentGap(
        hasDueDate: Bool,
        dueDateGap: CGFloat = DesignTokens.Spacing.taskDueDateGap,
        unsetDueDateGap: CGFloat = DesignTokens.Spacing.taskUnsetDueDateGap
    ) -> CGFloat {
        hasDueDate ? dueDateGap : unsetDueDateGap
    }

    static func leadingPadding(
        hasDueDate: Bool,
        rowSpacing: CGFloat = DesignTokens.Spacing.taskLeadingGap,
        dueDateGap: CGFloat = DesignTokens.Spacing.taskDueDateGap,
        unsetDueDateGap: CGFloat = DesignTokens.Spacing.taskUnsetDueDateGap
    ) -> CGFloat {
        max(
            contentGap(
                hasDueDate: hasDueDate,
                dueDateGap: dueDateGap,
                unsetDueDateGap: unsetDueDateGap
            ) - rowSpacing,
            0
        )
    }

    static func reservedWidth(
        hasDueDate: Bool,
        dueDateContentWidth: CGFloat,
        rowSpacing: CGFloat = DesignTokens.Spacing.taskLeadingGap,
        dueDateGap: CGFloat = DesignTokens.Spacing.taskDueDateGap,
        unsetDueDateGap: CGFloat = DesignTokens.Spacing.taskUnsetDueDateGap,
        trailingControlWidth: CGFloat = DesignTokens.Size.trailingControl,
        trailingInset: CGFloat = DesignTokens.Spacing.sectionPaddingHorizontal
            + DesignTokens.Spacing.partitionHeaderContentLeadingInset
            - DesignTokens.Spacing.rowHorizontal
    ) -> CGFloat {
        let contentWidth = hasDueDate
            ? max(dueDateContentWidth, trailingControlWidth)
            : trailingControlWidth
        return leadingPadding(
            hasDueDate: hasDueDate,
            rowSpacing: rowSpacing,
            dueDateGap: dueDateGap,
            unsetDueDateGap: unsetDueDateGap
        ) + contentWidth + trailingInset
    }
}

// MARK: - Task Item View

private struct HoverCursorModifier: ViewModifier {
    let cursor: NSCursor
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    cursor.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    isHovering = true
                    cursor.set()
                case .ended:
                    isHovering = false
                    NSCursor.arrow.set()
                }
            }
            .onDisappear {
                guard isHovering else { return }
                isHovering = false
                NSCursor.arrow.set()
            }
    }
}

private extension View {
    func hoverCursor(_ cursor: NSCursor) -> some View {
        modifier(HoverCursorModifier(cursor: cursor))
    }
}

private struct StarMarkerInteractionRegion: NSViewRepresentable {
    let cursor: NSCursor
    let onHover: (Bool) -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> StarMarkerInteractionNSView {
        let view = StarMarkerInteractionNSView()
        view.cursor = cursor
        view.onHover = onHover
        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: StarMarkerInteractionNSView, context: Context) {
        nsView.cursor = cursor
        nsView.onHover = onHover
        nsView.onClick = onClick
        nsView.updateTrackingAreas()
        nsView.window?.invalidateCursorRects(for: nsView)
    }
}

private final class StarMarkerInteractionNSView: NSView {
    var cursor: NSCursor = .arrow
    var onHover: (Bool) -> Void = { _ in }
    var onClick: () -> Void = {}

    private var trackingAreaRef: NSTrackingArea?

    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaRef = trackingArea
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: cursor)
    }

    override func mouseEntered(with event: NSEvent) {
        cursor.set()
        onHover(true)
    }

    override func mouseMoved(with event: NSEvent) {
        cursor.set()
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        onHover(false)
    }

    override func mouseDown(with event: NSEvent) {
        onClick()
    }
}

enum TaskItemRenderMode {
    case active
    case completed
}

enum StarMarkerPresentation {
    static func allowsInteraction(renderMode: TaskItemRenderMode) -> Bool {
        renderMode == .active
    }

    static func showsMarker(
        taskIsStarred: Bool,
        renderMode: TaskItemRenderMode,
        isHoveringRow: Bool,
        isHoveringMarker: Bool
    ) -> Bool {
        taskIsStarred || (renderMode == .active && (isHoveringRow || isHoveringMarker))
    }
}

struct TaskItemView: View {
    let task: TodoTask
    let depth: Int
    let renderMode: TaskItemRenderMode
    let allowsCompletionToggle: Bool
    let onSaveTask: (String, String) -> Void
    let onBeginAddChildTask: (String) -> Void
    let onToggleComplete: (String) -> Void
    let onToggleStar: (String) -> Void
    let onSetDueDate: (String, Date?) -> Void

    @State private var isHovering = false
    @State private var showDatePicker = false
    @State private var isEditing = false
    @State private var editingName: String = ""

    // Individual hover states for interactive elements
    @State private var isHoveringCheckbox = false
    @State private var isHoveringStar = false
    @State private var isHoveringCalendar = false

    init(
        task: TodoTask,
        depth: Int,
        renderMode: TaskItemRenderMode,
        allowsCompletionToggle: Bool = true,
        onSaveTask: @escaping (String, String) -> Void,
        onBeginAddChildTask: @escaping (String) -> Void,
        onToggleComplete: @escaping (String) -> Void,
        onToggleStar: @escaping (String) -> Void,
        onSetDueDate: @escaping (String, Date?) -> Void
    ) {
        self.task = task
        self.depth = depth
        self.renderMode = renderMode
        self.allowsCompletionToggle = allowsCompletionToggle
        self.onSaveTask = onSaveTask
        self.onBeginAddChildTask = onBeginAddChildTask
        self.onToggleComplete = onToggleComplete
        self.onToggleStar = onToggleStar
        self.onSetDueDate = onSetDueDate
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.taskLeadingGap) {
            leadingControls

            taskContent
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDueDateControl {
                dueDateControl
            }
        }
        .padding(.leading, CGFloat(depth) * DesignTokens.Spacing.childTaskIndent)
        .padding(.horizontal, DesignTokens.Spacing.rowHorizontal)
        .padding(.vertical, DesignTokens.Spacing.rowVertical)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.row, style: .continuous)
                .fill(isHovering ? DesignTokens.ColorRole.rowHover : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if showDatePicker {
                isHovering = true
            } else {
                isHovering = hovering
            }
        }
        .contextMenu {
            if task.isRootTask && renderMode == .active {
                Button("New Child Task") {
                    onBeginAddChildTask(task.id)
                }
            }
        }
        .overlay(alignment: .leading) {
            if StarMarkerPresentation.allowsInteraction(renderMode: renderMode) {
                StarMarkerInteractionRegion(
                    cursor: TodoCursors.starMarkerAction,
                    onHover: { isHoveringStar = $0 },
                    onClick: { onToggleStar(task.id) }
                )
                .frame(
                    width: DesignTokens.Size.starMarkerTapTargetWidth,
                    height: DesignTokens.Size.checkboxTapTarget
                )
                .padding(.leading, starMarkerHitRegionLeadingInset)
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var leadingControls: some View {
        ZStack(alignment: .leading) {
            starMarkerButton
            checkboxButton
                .padding(.leading, checkboxAlignedLeadingInset)
        }
        .frame(
            width: max(
                checkboxAlignedLeadingInset + DesignTokens.Size.checkboxTapTarget,
                DesignTokens.Size.starMarkerTapTargetWidth
            ),
            height: DesignTokens.Size.checkboxTapTarget,
            alignment: .leading
        )
    }

    private var taskContent: some View {
        HStack(spacing: DesignTokens.Spacing.tagGap) {
            ZStack(alignment: .leading) {
                renderedTaskSegments
                    .opacity(isEditing ? 0 : 1)
                    .allowsHitTesting(EditingLayerInteractivity.shouldAllowStaticDisplayHitTesting(isEditing: isEditing))
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        guard renderMode == .active else { return }
                        beginRename()
                    }

                InlineTaskNameEditor(
                    text: $editingName,
                    isEditing: isEditing,
                    onCommit: commitRename,
                    onCancel: cancelRename
                )
            }
            .frame(height: DesignTokens.Size.inlineTextEditorHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var renderedTaskSegments: some View {
        let segments = task.renderSegments

        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                switch segment {
                case .text(let text):
                    Text(text)
                        .font(DesignTokens.Typography.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(taskNameColor)
                        .strikethrough(task.isCompleted, color: DesignTokens.ColorRole.secondaryText)
                        .padding(.trailing, trailingGap(after: index, segments: segments))
                case .tag(let tag):
                    TaskTagChip(
                        text: tag,
                        style: renderMode == .completed ? .completed : .active
                    )
                    .fixedSize()
                    .padding(.trailing, trailingGap(after: index, segments: segments))
                }
            }
        }
        .hoverCursor(.iBeam)
    }

    private func trailingGap(after index: Int, segments: [TaskTextSegment]) -> CGFloat {
        guard index < segments.count - 1 else { return 0 }
        return segments[index].isTag || segments[index + 1].isTag
            ? DesignTokens.Spacing.inlineTagTextGap
            : 0
    }

    @ViewBuilder
    private var checkboxButton: some View {
        let button = Button {
            guard allowsCompletionToggle else { return }
            onToggleComplete(task.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.checkbox, style: .continuous)
                    .strokeBorder(
                        checkboxStrokeColor,
                        lineWidth: DesignTokens.Stroke.checkboxLineWidth
                    )
                    .frame(width: DesignTokens.Size.checkbox, height: DesignTokens.Size.checkbox)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.checkbox, style: .continuous)
                            .fill(checkboxFillColor)
                    )
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(DesignTokens.Typography.checkmark)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: DesignTokens.Size.checkboxTapTarget, height: DesignTokens.Size.checkboxTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHoveringCheckbox = $0 }
        .allowsHitTesting(allowsCompletionToggle)

        if allowsCompletionToggle {
            button.hoverCursor(.pointingHand)
        } else {
            button
        }
    }

    @ViewBuilder
    private var starMarkerButton: some View {
        let markerLeadingInset = DesignTokens.Spacing.starMarkerLeadingOffset
        let hitTargetLeadingOffset = checkboxAlignedLeadingInset - DesignTokens.Size.starMarkerTapTargetWidth
        let marker = RoundedRectangle(cornerRadius: DesignTokens.Radius.starMarker, style: .continuous)
            .fill(starMarkerColor)
            .frame(
                width: DesignTokens.Size.starMarkerWidth,
                height: DesignTokens.Size.starMarkerHeight
            )
            .rotationEffect(.degrees(14))
        let hitTarget = ZStack(alignment: .leading) {
            marker
                .offset(x: markerLeadingInset)
        }
            .frame(
                width: DesignTokens.Size.starMarkerTapTargetWidth,
                height: DesignTokens.Size.checkboxTapTarget,
                alignment: .leading
            )
            .contentShape(Rectangle())
            .offset(x: hitTargetLeadingOffset)

        if StarMarkerPresentation.allowsInteraction(renderMode: renderMode) {
            hitTarget
                .allowsHitTesting(false)
            .accessibilityLabel(task.isStarred ? "Remove star" : "Mark as starred")
        } else {
            hitTarget
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func dueDateLabel(_ dueDate: Date) -> some View {
        let daysFromToday = DateHelpers.daysFromToday(dueDate) ?? .max

        return Group {
            switch daysFromToday {
            case ..<0:
                dueDateTag(
                    text: DateHelpers.formatDueDate(dueDate),
                    background: DesignTokens.ColorRole.dueDateUrgentTag
                )
            case 0:
                dueDateTag(
                    text: DateHelpers.formatDueDate(dueDate),
                    background: DesignTokens.ColorRole.dueDateUrgentTag
                )
            case 1:
                outlinedDueDateTag(
                    text: DateHelpers.formatDueDate(dueDate)
                )
            case 2:
                outlinedDueDateTag(
                    text: DateHelpers.formatDueDate(dueDate)
                )
            default:
                plainDueDateText(DateHelpers.formatDueDate(dueDate))
            }
        }
    }

    private var dueDateControl: some View {
        Group {
            if let dueDate = task.dueDate {
                Button {
                    showDatePicker.toggle()
                } label: {
                    dueDateLabel(dueDate)
                }
                .buttonStyle(.plain)
                .hoverCursor(.pointingHand)
                .popover(isPresented: $showDatePicker) {
                    DatePickerPopover(
                        currentDate: task.dueDate,
                        onSelect: { date in
                            onSetDueDate(task.id, date)
                            showDatePicker = false
                        },
                        onRemove: {
                            onSetDueDate(task.id, nil)
                            showDatePicker = false
                        }
                    )
                }
            } else {
                Button {
                    showDatePicker.toggle()
                } label: {
                    Image(systemName: "calendar")
                        .font(DesignTokens.Typography.icon)
                        .foregroundStyle(isHoveringCalendar ? DesignTokens.ColorRole.primaryText : DesignTokens.ColorRole.secondaryText)
                        .frame(width: DesignTokens.Size.trailingControl, height: DesignTokens.Size.trailingControl)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { isHoveringCalendar = $0 }
                .hoverCursor(.pointingHand)
                .opacity(isHovering || showDatePicker ? 1 : 0)
                .popover(isPresented: $showDatePicker) {
                    DatePickerPopover(
                        currentDate: nil,
                        onSelect: { date in
                            onSetDueDate(task.id, date)
                            showDatePicker = false
                        },
                        onRemove: nil
                    )
                }
            }
        }
        .padding(.leading, dueDateLeadingPadding)
        .padding(.trailing, dueDateTrailingInset)
        .frame(width: dueDateReservedWidth, alignment: .trailing)
    }

    private var showsDueDateControl: Bool {
        renderMode == .active && !task.isCompleted
    }

    private func dueDateTag(text: String, background: Color) -> some View {
        dueDateText(text, color: DesignTokens.ColorRole.dueDateNeutralText)
            .padding(.horizontal, DueDateLabelLayout.textTrailingInset)
            .padding(.vertical, DesignTokens.Spacing.dueDateTagVertical)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.dueDateTag, style: .continuous)
                    .fill(background)
            )
    }

    private func outlinedDueDateTag(text: String) -> some View {
        let color = DesignTokens.ColorRole.secondaryText

        return dueDateText(text, color: color)
            .padding(.horizontal, DueDateLabelLayout.textTrailingInset)
            .padding(.vertical, DesignTokens.Spacing.dueDateTagVertical)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.dueDateTag, style: .continuous)
                    .strokeBorder(color, lineWidth: DesignTokens.Stroke.dueDateOutlineLineWidth)
            )
    }

    private func plainDueDateText(_ text: String) -> some View {
        dueDateText(text, color: DesignTokens.ColorRole.secondaryText)
            .padding(.trailing, DueDateLabelLayout.textTrailingInset)
    }

    private func dueDateText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.dueDateTag)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var starMarkerColor: Color {
        guard StarMarkerPresentation.showsMarker(
            taskIsStarred: task.isStarred,
            renderMode: renderMode,
            isHoveringRow: isHovering,
            isHoveringMarker: isHoveringStar
        ) else {
            return .clear
        }

        if task.isStarred {
            return task.isRootTask
                ? DesignTokens.ColorRole.dueDateUrgentTag
                : DesignTokens.ColorRole.primaryText.opacity(0.56)
        }

        if isHoveringStar {
            return task.isRootTask ? .white : Color.white.opacity(0.82)
        }

        if isHovering {
            return task.isRootTask
                ? Color.white.opacity(DesignTokens.Spacing.starMarkerPreviewOpacity)
                : DesignTokens.ColorRole.secondaryText.opacity(0.32)
        }

        return .clear
    }

    private var taskNameColor: Color {
        task.isCompleted ? DesignTokens.ColorRole.secondaryText : DesignTokens.ColorRole.primaryText
    }

    private var checkboxStrokeColor: Color {
        guard allowsCompletionToggle else {
            return DesignTokens.ColorRole.secondaryText.opacity(0.45)
        }

        if task.isCompleted {
            return DesignTokens.ColorRole.successMuted
        }

        return isHoveringCheckbox ? DesignTokens.ColorRole.primaryText : DesignTokens.ColorRole.secondaryText
    }

    private var checkboxFillColor: Color {
        if task.isCompleted {
            return DesignTokens.ColorRole.successMuted
        }

        if !allowsCompletionToggle {
            return DesignTokens.ColorRole.secondaryText.opacity(0.14)
        }

        return .clear
    }

    private var checkboxAlignedLeadingInset: CGFloat {
        TaskItemLeadingControlLayout.checkboxLeadingInset()
    }

    private var starMarkerHitRegionLeadingInset: CGFloat {
        TaskItemLeadingControlLayout.starMarkerHitRegionLeadingInset(depth: depth)
    }

    private var dueDateTrailingInset: CGFloat {
        DesignTokens.Spacing.sectionPaddingHorizontal
            + DesignTokens.Spacing.partitionHeaderContentLeadingInset
            - DesignTokens.Spacing.rowHorizontal
    }

    private var dueDateReservedWidth: CGFloat {
        TaskRowTrailingLayout.reservedWidth(
            hasDueDate: task.dueDate != nil,
            dueDateContentWidth: dueDateContentWidth,
            trailingInset: dueDateTrailingInset
        )
    }

    private var dueDateLeadingPadding: CGFloat {
        TaskRowTrailingLayout.leadingPadding(hasDueDate: task.dueDate != nil)
    }

    private var dueDateContentWidth: CGFloat {
        guard let dueDate = task.dueDate else { return 0 }
        let formattedDate = DateHelpers.formatDueDate(dueDate)
        let daysFromToday = DateHelpers.daysFromToday(dueDate) ?? .max

        switch daysFromToday {
        case ..<3:
            return DueDateLabelLayout.tagWidth(for: formattedDate)
        default:
            return DueDateLabelLayout.plainWidth(for: formattedDate)
        }
    }

    private func commitRename(_ displayText: String) {
        let parsed = TodoTask.parseDisplayText(displayText)
        if !parsed.name.isEmpty {
            onSaveTask(task.id, parsed.markupText)
        }
        isEditing = false
    }

    private func cancelRename() {
        isEditing = false
    }

    private func beginRename() {
        editingName = task.displayText
        isEditing = true
    }
}

private extension TaskTextSegment {
    var isTag: Bool {
        if case .tag = self { return true }
        return false
    }
}

// MARK: - Date Picker Popover

private struct DatePickerPopover: View {
    let currentDate: Date?
    let onSelect: (Date) -> Void
    let onRemove: (() -> Void)?

    @State private var selectedDate: Date
    @State private var displayedMonth: Date
    @State private var hoveredDay: Date?
    @State private var isHoveringRemoveDate = false

    private let calendar = Calendar.current

    init(
        currentDate: Date?,
        onSelect: @escaping (Date) -> Void,
        onRemove: (() -> Void)?
    ) {
        self.currentDate = currentDate
        self.onSelect = onSelect
        self.onRemove = onRemove
        let baseDate = Calendar.current.startOfDay(for: currentDate ?? Date())
        _selectedDate = State(initialValue: baseDate)
        _displayedMonth = State(initialValue: DatePickerPopover.monthStart(for: baseDate))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            calendarHeader
            weekdayHeader
            calendarGrid

            if currentDate != nil, let onRemove {
                Divider()

                Button {
                    onRemove()
                } label: {
                    Label("Remove Date", systemImage: "xmark")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(
                    isHoveringRemoveDate
                        ? DesignTokens.ColorRole.removeDateHover
                        : DesignTokens.ColorRole.removeDate
                )
                .font(DesignTokens.Typography.micro)
                .onHover { isHoveringRemoveDate = $0 }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.calendarPopoverHorizontal)
        .padding(.vertical, DesignTokens.Spacing.calendarPopoverVertical)
        .frame(width: DesignTokens.Size.datePopoverWidth)
    }

    private var calendarHeader: some View {
        HStack(spacing: DesignTokens.Spacing.calendarHeaderControlGap) {
            Text(monthTitle(for: displayedMonth))
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(DesignTokens.ColorRole.primaryText)

            Spacer()

            monthButton(systemName: "chevron.left") {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            }

            monthButton(systemName: "chevron.right") {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            }
        }
    }

    private var weekdayHeader: some View {
        let labels = reorderedWeekdaySymbols()

        return HStack(spacing: DesignTokens.Spacing.calendarGridGap) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.calendarGridGap),
                count: 7
            ),
            spacing: DesignTokens.Spacing.calendarGridGap
        ) {
            ForEach(dayCells()) { day in
                Button {
                    let normalized = calendar.startOfDay(for: day.date)
                    selectedDate = normalized
                    onSelect(normalized)
                } label: {
                    Text(day.label)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundStyle(dayTextColor(for: day))
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Size.calendarDayCell)
                        .background(dayBackground(for: day))
                        .overlay(dayOutline(for: day))
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: DesignTokens.Radius.calendarDay,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredDay = hovering ? day.date : (hoveredDay == day.date ? nil : hoveredDay)
                }
            }
        }
    }

    @ViewBuilder
    private func dayBackground(for day: CalendarDayCell) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        let isHovered = hoveredDay.map { calendar.isDate($0, inSameDayAs: day.date) } ?? false

        RoundedRectangle(cornerRadius: DesignTokens.Radius.calendarDay, style: .continuous)
            .fill(
                isSelected
                    ? DesignTokens.ColorRole.dueDateUrgentTag
                    : (isHovered ? DesignTokens.ColorRole.calendarHover : Color.clear)
            )
    }

    @ViewBuilder
    private func dayOutline(for day: CalendarDayCell) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day.date)

        RoundedRectangle(cornerRadius: DesignTokens.Radius.calendarDay, style: .continuous)
            .stroke(
                isToday && !isSelected
                    ? DesignTokens.ColorRole.calendarTodayStroke
                    : Color.clear,
                lineWidth: 1
            )
    }

    private func dayTextColor(for day: CalendarDayCell) -> Color {
        if calendar.isDate(day.date, inSameDayAs: selectedDate) {
            return DesignTokens.ColorRole.dueDateNeutralText
        }

        return day.isInDisplayedMonth
            ? DesignTokens.ColorRole.primaryText
            : DesignTokens.ColorRole.tertiaryText
    }

    private func monthButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                .frame(
                    width: DesignTokens.Size.calendarNavControl,
                    height: DesignTokens.Size.calendarNavControl
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: DesignTokens.Radius.calendarNavButton,
                        style: .continuous
                    )
                    .fill(DesignTokens.ColorRole.calendarHover)
                )
        }
        .buttonStyle(.plain)
    }

    private func reorderedWeekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        let symbols = formatter.shortWeekdaySymbols ?? []

        guard !symbols.isEmpty else { return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] }

        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func dayCells() -> [CalendarDayCell] {
        let monthStart = DatePickerPopover.monthStart(for: displayedMonth)
        let monthWeekday = calendar.component(.weekday, from: monthStart)
        let leadingOffset = (monthWeekday - calendar.firstWeekday + 7) % 7
        let firstVisibleDate = calendar.date(byAdding: .day, value: -leadingOffset, to: monthStart) ?? monthStart

        return (0..<42).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index, to: firstVisibleDate) else {
                return nil
            }

            return CalendarDayCell(
                date: date,
                label: "\(calendar.component(.day, from: date))",
                isInDisplayedMonth: calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            )
        }
    }

    private static func monthStart(for date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: components) ?? date
    }
}

private struct CalendarDayCell: Identifiable {
    let date: Date
    let label: String
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "今晚提交首页视觉稿", tags: ["Brand", "Launch"], isStarred: true, dueDate: Date()),
            depth: 0,
            renderMode: .active,
            onSaveTask: { _, _ in },
            onBeginAddChildTask: { _ in },
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in }
        )
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "整理会议记录", parentTaskId: "root"),
            depth: 1,
            renderMode: .active,
            onSaveTask: { _, _ in },
            onBeginAddChildTask: { _ in },
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in }
        )
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "发送周报", isCompleted: true),
            depth: 0,
            renderMode: .completed,
            onSaveTask: { _, _ in },
            onBeginAddChildTask: { _ in },
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in }
        )
    }
    .padding()
    .frame(width: 350)
}
