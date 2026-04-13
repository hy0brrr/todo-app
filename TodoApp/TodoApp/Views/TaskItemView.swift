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

// MARK: - Task Item View

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func trailingGap(after index: Int, segments: [TaskTextSegment]) -> CGFloat {
        guard index < segments.count - 1 else { return 0 }
        return segments[index].isTag || segments[index + 1].isTag
            ? DesignTokens.Spacing.inlineTagTextGap
            : 0
    }

    private var checkboxButton: some View {
        Button {
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
    }

    @ViewBuilder
    private var starMarkerButton: some View {
        let marker = RoundedRectangle(cornerRadius: DesignTokens.Radius.starMarker, style: .continuous)
            .fill(starMarkerColor)
            .frame(
                width: DesignTokens.Size.starMarkerWidth,
                height: DesignTokens.Size.starMarkerHeight
            )
            .rotationEffect(.degrees(14))
            .frame(
                width: DesignTokens.Size.starMarkerTapTargetWidth,
                height: DesignTokens.Size.checkboxTapTarget
            )
            .contentShape(Rectangle())
            .offset(x: DesignTokens.Spacing.starMarkerLeadingOffset)

        if StarMarkerPresentation.allowsInteraction(renderMode: renderMode) {
            Button {
                onToggleStar(task.id)
            } label: {
                marker
            }
            .buttonStyle(.plain)
            .onHover { isHoveringStar = $0 }
            .allowsHitTesting(task.isStarred || isHovering || isHoveringStar)
            .accessibilityLabel(task.isStarred ? "Remove star" : "Mark as starred")
        } else {
            marker
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func dueDateLabel(_ dueDate: Date) -> some View {
        let daysFromToday = DateHelpers.daysFromToday(dueDate) ?? .max

        Group {
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
                Text(DateHelpers.formatDueDate(dueDate))
                    .font(DesignTokens.Typography.dueDateTag)
                    .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                    .padding(.trailing, DesignTokens.Spacing.dueDateTagHorizontal)
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
        .padding(.leading, DesignTokens.Spacing.taskDueDateGap)
        .padding(.trailing, dueDateTrailingInset)
        .frame(width: DesignTokens.Size.dueDateColumnWidth, alignment: .trailing)
    }

    private var showsDueDateControl: Bool {
        renderMode == .active && !task.isCompleted
    }

    private func dueDateTag(text: String, background: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.dueDateTag)
            .foregroundStyle(DesignTokens.ColorRole.dueDateNeutralText)
            .padding(.horizontal, DesignTokens.Spacing.dueDateTagHorizontal)
            .padding(.vertical, DesignTokens.Spacing.dueDateTagVertical)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.dueDateTag, style: .continuous)
                    .fill(background)
            )
    }

    private func outlinedDueDateTag(text: String) -> some View {
        let color = DesignTokens.ColorRole.secondaryText

        return Text(text)
            .font(DesignTokens.Typography.dueDateTag)
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.dueDateTagHorizontal)
            .padding(.vertical, DesignTokens.Spacing.dueDateTagVertical)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.dueDateTag, style: .continuous)
                    .strokeBorder(color, lineWidth: DesignTokens.Stroke.dueDateOutlineLineWidth)
            )
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
        let checkboxVisualInset = (DesignTokens.Size.checkboxTapTarget - DesignTokens.Size.checkbox) / 2
        return DesignTokens.Spacing.sectionPaddingHorizontal
            + DesignTokens.Spacing.partitionHeaderContentLeadingInset
            - DesignTokens.Spacing.rowHorizontal
            - checkboxVisualInset
    }

    private var dueDateTrailingInset: CGFloat {
        DesignTokens.Spacing.sectionPaddingHorizontal
            + DesignTokens.Spacing.partitionHeaderContentLeadingInset
            - DesignTokens.Spacing.rowHorizontal
    }

    private func commitRename() {
        let parsed = TodoTask.parseDisplayText(editingName)
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
