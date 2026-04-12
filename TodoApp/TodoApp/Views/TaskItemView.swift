import SwiftUI
import AppKit

// MARK: - Click-Outside Monitor (macOS)

/// Monitors for mouse-down events outside of NSTextView (which backs SwiftUI TextField).
/// When a click is detected outside the text field, it fires the provided action.
private class ClickOutsideHandler {
    private var monitor: Any?

    func install(action: @escaping () -> Void) {
        uninstall()
        // Delay slightly to avoid catching the double-click that triggered editing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard self != nil else { return }
            self?.monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
                if let contentView = event.window?.contentView {
                    let locationInView = contentView.convert(event.locationInWindow, from: nil)
                    if let hitView = contentView.hitTest(locationInView) {
                        // NSTextView is the AppKit view backing a SwiftUI TextField.
                        // If the click target is NOT a text view, the user clicked outside.
                        if !(hitView is NSTextView) {
                            DispatchQueue.main.async {
                                action()
                            }
                        }
                    }
                }
                return event
            }
        }
    }

    func uninstall() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        uninstall()
    }
}

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

        init(text: Binding<String>, onCommit: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self._text = text
            self.onCommit = onCommit
            self.onCancel = onCancel
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                text = textView.string
                onCommit()
                return true
            }

            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onCancel()
                return true
            }

            return false
        }
    }
}

// MARK: - Task Item View

struct TaskItemView: View {
    let task: TodoTask
    let onToggleComplete: (String) -> Void
    let onToggleStar: (String) -> Void
    let onSetDueDate: (String, Date?) -> Void
    let onRename: (String, String) -> Void

    @State private var isHovering = false
    @State private var showDatePicker = false
    @State private var isEditing = false
    @State private var editingName: String = ""

    // Individual hover states for interactive elements
    @State private var isHoveringCheckbox = false
    @State private var isHoveringStar = false
    @State private var isHoveringCalendar = false

    @State private var clickHandler = ClickOutsideHandler()

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.taskLeadingGap) {
            leadingControls

            ZStack(alignment: .leading) {
                Text(task.name)
                    .font(DesignTokens.Typography.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(task.isCompleted ? DesignTokens.ColorRole.secondaryText : DesignTokens.ColorRole.primaryText)
                    .strikethrough(task.isCompleted, color: DesignTokens.ColorRole.secondaryText)
                    .opacity(isEditing ? 0 : 1)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        guard !task.isCompleted else { return }
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

            if !task.isCompleted {
                dueDateControl
            }
        }
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

    private var checkboxButton: some View {
        Button {
            onToggleComplete(task.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.checkbox, style: .continuous)
                    .strokeBorder(
                        task.isCompleted
                            ? DesignTokens.ColorRole.successMuted
                            : (isHoveringCheckbox ? DesignTokens.ColorRole.primaryText : DesignTokens.ColorRole.secondaryText),
                        lineWidth: DesignTokens.Stroke.checkboxLineWidth
                    )
                    .frame(width: DesignTokens.Size.checkbox, height: DesignTokens.Size.checkbox)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.checkbox, style: .continuous)
                            .fill(task.isCompleted ? DesignTokens.ColorRole.successMuted : Color.clear)
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
    }

    private var starMarkerButton: some View {
        Button {
            onToggleStar(task.id)
        } label: {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.starMarker, style: .continuous)
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
        }
        .buttonStyle(.plain)
        .onHover { isHoveringStar = $0 }
        .offset(x: DesignTokens.Spacing.starMarkerLeadingOffset)
        .allowsHitTesting(task.isStarred || isHovering || isHoveringStar)
        .accessibilityLabel(task.isStarred ? "Remove star" : "Mark as starred")
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
        if task.isStarred {
            return DesignTokens.ColorRole.dueDateUrgentTag
        }

        if isHoveringStar {
            return .white
        }

        if isHovering {
            return Color.white.opacity(DesignTokens.Spacing.starMarkerPreviewOpacity)
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
        clickHandler.uninstall()
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            onRename(task.id, trimmed)
        }
        isEditing = false
    }

    private func cancelRename() {
        clickHandler.uninstall()
        isEditing = false
    }

    private func beginRename() {
        editingName = task.name
        isEditing = true
        clickHandler.install { [self] in
            commitRename()
        }
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
            task: TodoTask(partitionId: "p1", name: "今晚提交首页视觉稿", isStarred: true, dueDate: Date()),
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in },
            onRename: { _, _ in }
        )
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "整理会议记录"),
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in },
            onRename: { _, _ in }
        )
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "发送周报", isCompleted: true),
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in },
            onRename: { _, _ in }
        )
    }
    .padding()
    .frame(width: 350)
}
