import SwiftUI
import AppKit

private final class InlineEditingTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if TextEditingCommandBridge.performKeyEquivalent(event, in: self) {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}

private struct InlineTaskNameEditor: NSViewRepresentable {
    @Binding var text: String
    let density: InterfaceDensity
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
        let fontSize = DesignTokens.Typography.bodySize(in: density)
        if let customFont = NSFont(name: "PingFangSC-Regular", size: fontSize) {
            return customFont
        }

        return .systemFont(ofSize: fontSize, weight: .regular)
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
            ((obj.object as? NSTextField)?.currentEditor() as? NSTextView)?.allowsUndo = true
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
        density: InterfaceDensity = .regular,
        sectionPaddingHorizontal: CGFloat? = nil,
        partitionHeaderContentLeadingInset: CGFloat? = nil,
        rowHorizontal: CGFloat? = nil,
        checkboxTapTarget: CGFloat? = nil,
        checkbox: CGFloat? = nil
    ) -> CGFloat {
        let sectionPaddingHorizontal = sectionPaddingHorizontal ?? DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density)
        let partitionHeaderContentLeadingInset = partitionHeaderContentLeadingInset ?? DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density)
        let rowHorizontal = rowHorizontal ?? DesignTokens.Spacing.scaledRowHorizontal(in: density)
        let checkboxTapTarget = checkboxTapTarget ?? DesignTokens.Size.scaledCheckboxTapTarget(in: density)
        let checkbox = checkbox ?? DesignTokens.Size.scaledCheckbox(in: density)
        let checkboxVisualInset = (checkboxTapTarget - checkbox) / 2
        return sectionPaddingHorizontal
            + partitionHeaderContentLeadingInset
            - rowHorizontal
            - checkboxVisualInset
    }

    static func starMarkerHitRegionLeadingInset(
        depth: Int,
        density: InterfaceDensity = .regular,
        rowHorizontal: CGFloat? = nil,
        childTaskIndent: CGFloat? = nil,
        checkboxLeadingInsetOverride: CGFloat? = nil,
        starMarkerTapTargetWidth: CGFloat? = nil
    ) -> CGFloat {
        let rowHorizontal = rowHorizontal ?? DesignTokens.Spacing.scaledRowHorizontal(in: density)
        let childTaskIndent = childTaskIndent ?? DesignTokens.Spacing.scaledChildTaskIndent(in: density)
        let checkboxLeadingInset = checkboxLeadingInsetOverride ?? checkboxLeadingInset(density: density)
        let starMarkerTapTargetWidth = starMarkerTapTargetWidth ?? DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: density)
        return rowHorizontal
            + (CGFloat(depth) * childTaskIndent)
            + checkboxLeadingInset
            - starMarkerTapTargetWidth
    }
}

enum DueDateLabelLayout {
    static let textWidth: CGFloat = DesignTokens.Size.dueDateTextContentWidth
    static let textTrailingInset: CGFloat = DesignTokens.Spacing.dueDateTagHorizontal
    static let renderingAllowance: CGFloat = 4

    static var labelWidth: CGFloat {
        textWidth + (textTrailingInset * 2)
    }

    static func tagWidth(for text: String) -> CGFloat {
        textWidth(for: text) + (textTrailingInset * 2) + renderingAllowance
    }

    static func scaledTextTrailingInset(in density: InterfaceDensity) -> CGFloat {
        DesignTokens.Spacing.scaledDueDateTagHorizontal(in: density)
    }

    static func tagWidth(for text: String, density: InterfaceDensity) -> CGFloat {
        textWidth(for: text, density: density)
            + (scaledTextTrailingInset(in: density) * 2)
            + DesignTokens.scaled(renderingAllowance, in: density)
    }

    static func plainWidth(for text: String) -> CGFloat {
        textWidth(for: text) + textTrailingInset + renderingAllowance
    }

    static func plainWidth(for text: String, density: InterfaceDensity) -> CGFloat {
        textWidth(for: text, density: density)
            + scaledTextTrailingInset(in: density)
            + DesignTokens.scaled(renderingAllowance, in: density)
    }

    private static func textWidth(for text: String) -> CGFloat {
        let font = NSFont(name: "PingFangSC-Regular", size: 11) ?? .systemFont(ofSize: 11, weight: .regular)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    private static func textWidth(for text: String, density: InterfaceDensity) -> CGFloat {
        let fontSize = DesignTokens.Typography.dueDateTagSize(in: density)
        let font = NSFont(name: "PingFangSC-Regular", size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .regular)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }
}

enum TaskRowTrailingLayout {
    static func contentGap(
        hasDueDate: Bool,
        density: InterfaceDensity = .regular,
        dueDateGap: CGFloat? = nil,
        unsetDueDateGap: CGFloat? = nil
    ) -> CGFloat {
        let dueDateGap = dueDateGap ?? DesignTokens.Spacing.scaledTaskDueDateGap(in: density)
        let unsetDueDateGap = unsetDueDateGap ?? DesignTokens.Spacing.scaledTaskUnsetDueDateGap(in: density)
        return hasDueDate ? dueDateGap : unsetDueDateGap
    }

    static func leadingPadding(
        hasDueDate: Bool,
        density: InterfaceDensity = .regular,
        rowSpacing: CGFloat? = nil,
        dueDateGap: CGFloat? = nil,
        unsetDueDateGap: CGFloat? = nil
    ) -> CGFloat {
        let rowSpacing = rowSpacing ?? DesignTokens.Spacing.scaledTaskLeadingGap(in: density)
        return max(
            contentGap(
                hasDueDate: hasDueDate,
                density: density,
                dueDateGap: dueDateGap,
                unsetDueDateGap: unsetDueDateGap
            ) - rowSpacing,
            0
        )
    }

    static func reservedWidth(
        hasDueDate: Bool,
        dueDateContentWidth: CGFloat,
        density: InterfaceDensity = .regular,
        rowSpacing: CGFloat? = nil,
        dueDateGap: CGFloat? = nil,
        unsetDueDateGap: CGFloat? = nil,
        trailingControlWidth: CGFloat? = nil,
        trailingInset: CGFloat? = nil
    ) -> CGFloat {
        let trailingControlWidth = trailingControlWidth ?? DesignTokens.Size.scaledTrailingControl(in: density)
        let trailingInset = trailingInset ?? DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density)
            + DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density)
            - DesignTokens.Spacing.scaledRowHorizontal(in: density)
        let contentWidth = hasDueDate
            ? max(dueDateContentWidth, trailingControlWidth)
            : trailingControlWidth
        return leadingPadding(
            hasDueDate: hasDueDate,
            density: density,
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

enum FallingTaskCoordinateSpace {
    static let name = "fallingTaskSpace"
}

struct TaskItemFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

enum StarMarkerFillStyle: Equatable {
    case clear
    case dueDateUrgentTag
    case primaryText(opacity: Double)
    case secondaryText(opacity: Double)

    var color: Color {
        switch self {
        case .clear:
            return .clear
        case .dueDateUrgentTag:
            return DesignTokens.ColorRole.dueDateUrgentTag
        case .primaryText(let opacity):
            return DesignTokens.ColorRole.primaryText.opacity(opacity)
        case .secondaryText(let opacity):
            return DesignTokens.ColorRole.secondaryText.opacity(opacity)
        }
    }
}

struct StarMarkerHoverState: Equatable {
    let isHoveringRow: Bool
    let isHoveringMarker: Bool
    let suppressesMarkerHoverUntilExit: Bool
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

    static func fillStyle(
        taskIsRoot: Bool,
        taskIsStarred: Bool,
        renderMode: TaskItemRenderMode,
        isHoveringRow: Bool,
        isHoveringMarker: Bool
    ) -> StarMarkerFillStyle {
        guard showsMarker(
            taskIsStarred: taskIsStarred,
            renderMode: renderMode,
            isHoveringRow: isHoveringRow,
            isHoveringMarker: isHoveringMarker
        ) else {
            return .clear
        }

        if taskIsStarred {
            return taskIsRoot
                ? .dueDateUrgentTag
                : .primaryText(opacity: 0.56)
        }

        if isHoveringMarker {
            return taskIsRoot
                ? .primaryText(opacity: 1)
                : .primaryText(opacity: 0.72)
        }

        if isHoveringRow {
            return taskIsRoot
                ? .primaryText(opacity: DesignTokens.Spacing.starMarkerPreviewOpacity)
                : .secondaryText(opacity: 0.32)
        }

        return .clear
    }

    static func hoverStateAfterStarStateChange(
        wasHoveringRow: Bool,
        wasHoveringMarker: Bool,
        suppressesMarkerHoverUntilExit: Bool
    ) -> StarMarkerHoverState {
        StarMarkerHoverState(
            isHoveringRow: false,
            isHoveringMarker: false,
            suppressesMarkerHoverUntilExit: wasHoveringMarker || suppressesMarkerHoverUntilExit
        )
    }

    static func hoverStateAfterMarkerHoverChange(
        isHoveringMarker: Bool,
        isHoveringRow: Bool,
        suppressesMarkerHoverUntilExit: Bool
    ) -> StarMarkerHoverState {
        guard suppressesMarkerHoverUntilExit else {
            return StarMarkerHoverState(
                isHoveringRow: isHoveringRow,
                isHoveringMarker: isHoveringMarker,
                suppressesMarkerHoverUntilExit: false
            )
        }

        return StarMarkerHoverState(
            isHoveringRow: isHoveringMarker ? false : isHoveringRow,
            isHoveringMarker: false,
            suppressesMarkerHoverUntilExit: isHoveringMarker
        )
    }
}

struct TaskItemView: View {
    @Environment(\.interfaceDensity) private var density

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
    @State private var suppressesStarHoverUntilExit = false

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
        HStack(spacing: DesignTokens.Spacing.scaledTaskLeadingGap(in: density)) {
            leadingControls

            taskContent
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDueDateControl {
                dueDateControl
            }
        }
        .padding(.leading, CGFloat(depth) * DesignTokens.Spacing.scaledChildTaskIndent(in: density))
        .padding(.horizontal, DesignTokens.Spacing.scaledRowHorizontal(in: density))
        .padding(.vertical, DesignTokens.Spacing.scaledRowVertical(in: density))
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledRow(in: density), style: .continuous)
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
        .onChange(of: task.isStarred) { _, _ in
            let hoverState = StarMarkerPresentation.hoverStateAfterStarStateChange(
                wasHoveringRow: isHovering,
                wasHoveringMarker: isHoveringStar,
                suppressesMarkerHoverUntilExit: suppressesStarHoverUntilExit
            )
            isHovering = hoverState.isHoveringRow
            isHoveringStar = hoverState.isHoveringMarker
            suppressesStarHoverUntilExit = hoverState.suppressesMarkerHoverUntilExit
        }
        .overlay(alignment: .leading) {
            if StarMarkerPresentation.allowsInteraction(renderMode: renderMode) {
                StarMarkerInteractionRegion(
                    cursor: TodoCursors.starMarkerAction,
                    onHover: { hovering in
                        let hoverState = StarMarkerPresentation.hoverStateAfterMarkerHoverChange(
                            isHoveringMarker: hovering,
                            isHoveringRow: isHovering,
                            suppressesMarkerHoverUntilExit: suppressesStarHoverUntilExit
                        )
                        isHovering = hoverState.isHoveringRow
                        isHoveringStar = hoverState.isHoveringMarker
                        suppressesStarHoverUntilExit = hoverState.suppressesMarkerHoverUntilExit
                    },
                    onClick: { onToggleStar(task.id) }
                )
                .frame(
                    width: DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: density),
                    height: DesignTokens.Size.scaledCheckboxTapTarget(in: density)
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
                checkboxAlignedLeadingInset + DesignTokens.Size.scaledCheckboxTapTarget(in: density),
                DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: density)
            ),
            height: DesignTokens.Size.scaledCheckboxTapTarget(in: density),
            alignment: .leading
        )
    }

    private var taskContent: some View {
        HStack(spacing: DesignTokens.Spacing.scaledTagGap(in: density)) {
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
                    density: density,
                    isEditing: isEditing,
                    onCommit: commitRename,
                    onCancel: cancelRename
                )
            }
            .frame(height: DesignTokens.Size.scaledInlineTextEditorHeight(in: density))
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
                        .font(DesignTokens.Typography.body(in: density))
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
        .background {
            if renderMode == .active {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: TaskItemFramePreferenceKey.self,
                        value: [task.id: proxy.frame(in: .named(FallingTaskCoordinateSpace.name))]
                    )
                }
            }
        }
        .hoverCursor(.iBeam)
    }

    private func trailingGap(after index: Int, segments: [TaskTextSegment]) -> CGFloat {
        guard index < segments.count - 1 else { return 0 }
        return segments[index].isTag || segments[index + 1].isTag
            ? DesignTokens.Spacing.scaledInlineTagTextGap(in: density)
            : 0
    }

    @ViewBuilder
    private var checkboxButton: some View {
        let button = Button {
            guard allowsCompletionToggle else { return }
            onToggleComplete(task.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCheckbox(in: density), style: .continuous)
                    .strokeBorder(
                        checkboxStrokeColor,
                        lineWidth: DesignTokens.Stroke.scaledCheckboxLineWidth(in: density)
                    )
                    .frame(width: DesignTokens.Size.scaledCheckbox(in: density), height: DesignTokens.Size.scaledCheckbox(in: density))
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCheckbox(in: density), style: .continuous)
                            .fill(checkboxFillColor)
                    )
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(DesignTokens.Typography.checkmark(in: density))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: DesignTokens.Size.scaledCheckboxTapTarget(in: density), height: DesignTokens.Size.scaledCheckboxTapTarget(in: density))
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
        let markerLeadingInset = DesignTokens.Spacing.scaledStarMarkerLeadingOffset(in: density)
        let hitTargetLeadingOffset = checkboxAlignedLeadingInset - DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: density)
        let marker = RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledStarMarker(in: density), style: .continuous)
            .fill(starMarkerColor)
            .frame(
                width: DesignTokens.Size.scaledStarMarkerWidth(in: density),
                height: DesignTokens.Size.scaledStarMarkerHeight(in: density)
            )
            .rotationEffect(.degrees(14))
        let hitTarget = ZStack(alignment: .leading) {
            marker
                .offset(x: markerLeadingInset)
        }
            .frame(
                width: DesignTokens.Size.scaledStarMarkerTapTargetWidth(in: density),
                height: DesignTokens.Size.scaledCheckboxTapTarget(in: density),
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
                        .font(DesignTokens.Typography.icon(in: density))
                        .foregroundStyle(isHoveringCalendar ? DesignTokens.ColorRole.primaryText : DesignTokens.ColorRole.secondaryText)
                        .frame(width: DesignTokens.Size.scaledTrailingControl(in: density), height: DesignTokens.Size.scaledTrailingControl(in: density))
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
            .padding(.horizontal, DueDateLabelLayout.scaledTextTrailingInset(in: density))
            .padding(.vertical, DesignTokens.Spacing.scaledDueDateTagVertical(in: density))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledDueDateTag(in: density), style: .continuous)
                    .fill(background)
            )
    }

    private func outlinedDueDateTag(text: String) -> some View {
        let color = DesignTokens.ColorRole.secondaryText

        return dueDateText(text, color: color)
            .padding(.horizontal, DueDateLabelLayout.scaledTextTrailingInset(in: density))
            .padding(.vertical, DesignTokens.Spacing.scaledDueDateTagVertical(in: density))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledDueDateTag(in: density), style: .continuous)
                    .strokeBorder(color, lineWidth: DesignTokens.Stroke.scaledDueDateOutlineLineWidth(in: density))
            )
    }

    private func plainDueDateText(_ text: String) -> some View {
        dueDateText(text, color: DesignTokens.ColorRole.secondaryText)
            .padding(.trailing, DueDateLabelLayout.scaledTextTrailingInset(in: density))
    }

    private func dueDateText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.dueDateTag(in: density))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var starMarkerColor: Color {
        StarMarkerPresentation.fillStyle(
            taskIsRoot: task.isRootTask,
            taskIsStarred: task.isStarred,
            renderMode: renderMode,
            isHoveringRow: isHovering,
            isHoveringMarker: isHoveringStar
        ).color
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
        TaskItemLeadingControlLayout.checkboxLeadingInset(density: density)
    }

    private var starMarkerHitRegionLeadingInset: CGFloat {
        TaskItemLeadingControlLayout.starMarkerHitRegionLeadingInset(depth: depth, density: density)
    }

    private var dueDateTrailingInset: CGFloat {
        DesignTokens.Spacing.scaledSectionPaddingHorizontal(in: density)
            + DesignTokens.Spacing.scaledPartitionHeaderContentLeadingInset(in: density)
            - DesignTokens.Spacing.scaledRowHorizontal(in: density)
    }

    private var dueDateReservedWidth: CGFloat {
        TaskRowTrailingLayout.reservedWidth(
            hasDueDate: task.dueDate != nil,
            dueDateContentWidth: dueDateContentWidth,
            density: density,
            trailingInset: dueDateTrailingInset
        )
    }

    private var dueDateLeadingPadding: CGFloat {
        TaskRowTrailingLayout.leadingPadding(hasDueDate: task.dueDate != nil, density: density)
    }

    private var dueDateContentWidth: CGFloat {
        guard let dueDate = task.dueDate else { return 0 }
        let formattedDate = DateHelpers.formatDueDate(dueDate)
        let daysFromToday = DateHelpers.daysFromToday(dueDate) ?? .max

        switch daysFromToday {
        case ..<3:
            return DueDateLabelLayout.tagWidth(for: formattedDate, density: density)
        default:
            return DueDateLabelLayout.plainWidth(for: formattedDate, density: density)
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
    @Environment(\.interfaceDensity) private var density

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
        VStack(alignment: .leading, spacing: DesignTokens.scaled(10, in: density)) {
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
                .font(DesignTokens.Typography.micro(in: density))
                .onHover { isHoveringRemoveDate = $0 }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.scaledCalendarPopoverHorizontal(in: density))
        .padding(.vertical, DesignTokens.Spacing.scaledCalendarPopoverVertical(in: density))
        .frame(width: DesignTokens.Size.scaledDatePopoverWidth(in: density))
    }

    private var calendarHeader: some View {
        HStack(spacing: DesignTokens.Spacing.scaledCalendarHeaderControlGap(in: density)) {
            Text(monthTitle(for: displayedMonth))
                .font(DesignTokens.Typography.bodyMedium(in: density))
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

        return HStack(spacing: DesignTokens.Spacing.scaledCalendarGridGap(in: density)) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(DesignTokens.Typography.micro(in: density))
                    .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.scaledCalendarGridGap(in: density)),
                count: 7
            ),
            spacing: DesignTokens.Spacing.scaledCalendarGridGap(in: density)
        ) {
            ForEach(dayCells()) { day in
                Button {
                    let normalized = calendar.startOfDay(for: day.date)
                    selectedDate = normalized
                    onSelect(normalized)
                } label: {
                    Text(day.label)
                        .font(DesignTokens.Typography.bodyMedium(in: density))
                        .foregroundStyle(dayTextColor(for: day))
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Size.scaledCalendarDayCell(in: density))
                        .background(dayBackground(for: day))
                        .overlay(dayOutline(for: day))
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: DesignTokens.Radius.scaledCalendarDay(in: density),
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

        RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCalendarDay(in: density), style: .continuous)
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

        RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCalendarDay(in: density), style: .continuous)
            .stroke(
                isToday && !isSelected
                    ? DesignTokens.ColorRole.calendarTodayStroke
                    : Color.clear,
                lineWidth: DesignTokens.scaled(1, in: density)
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
                .font(DesignTokens.Typography.micro(in: density))
                .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                .frame(
                    width: DesignTokens.Size.scaledCalendarNavControl(in: density),
                    height: DesignTokens.Size.scaledCalendarNavControl(in: density)
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: DesignTokens.Radius.scaledCalendarNavButton(in: density),
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
