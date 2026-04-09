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

    @FocusState private var isNameFieldFocused: Bool
    @State private var clickHandler = ClickOutsideHandler()

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.taskLeadingGap) {
            leadingControls

            // Task name — double-click to edit, click outside to save
            if isEditing {
                TextField("Task name", text: $editingName)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.ColorRole.primaryText)
                    .padding(.horizontal, DesignTokens.Spacing.inputHorizontal)
                    .padding(.vertical, DesignTokens.Spacing.inputVertical)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
                            .fill(DesignTokens.ColorRole.inputBackground)
                    )
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        commitRename()
                    }
                    .onExitCommand {
                        cancelRename()
                    }
                    .onAppear {
                        isNameFieldFocused = true
                        clickHandler.install { [self] in
                            self.commitRename()
                        }
                    }
                    .onDisappear {
                        clickHandler.uninstall()
                    }
            } else {
                Text(task.name)
                    .font(DesignTokens.Typography.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(task.isCompleted ? DesignTokens.ColorRole.secondaryText : DesignTokens.ColorRole.primaryText)
                    .strikethrough(task.isCompleted, color: DesignTokens.ColorRole.secondaryText)
                    .onTapGesture(count: 2) {
                        guard !task.isCompleted else { return }
                        editingName = task.name
                        isEditing = true
                    }
            }

            Spacer()

            if !task.isCompleted {
                // --- Due date area ---
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
                            hasExistingDate: true,
                            onSelect: { date in
                                onSetDueDate(task.id, date)
                                showDatePicker = false
                            },
                            onRemove: {
                                onSetDueDate(task.id, nil)
                                showDatePicker = false
                            },
                            onCancel: {
                                showDatePicker = false
                            }
                        )
                    }
                } else {
                    // Task has NO due date — calendar icon with hover effect
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
                            hasExistingDate: false,
                            onSelect: { date in
                                onSetDueDate(task.id, date)
                                showDatePicker = false
                            },
                            onRemove: nil,
                            onCancel: {
                                showDatePicker = false
                            }
                        )
                    }
                }
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
        .frame(minWidth: DesignTokens.Size.dueDateColumnMinWidth, alignment: .trailing)
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
}

// MARK: - Date Picker Popover

private struct DatePickerPopover: View {
    let currentDate: Date?
    let hasExistingDate: Bool
    let onSelect: (Date) -> Void
    let onRemove: (() -> Void)?
    let onCancel: () -> Void

    @State private var selectedDate: Date

    init(
        currentDate: Date?,
        hasExistingDate: Bool,
        onSelect: @escaping (Date) -> Void,
        onRemove: (() -> Void)?,
        onCancel: @escaping () -> Void
    ) {
        self.currentDate = currentDate
        self.hasExistingDate = hasExistingDate
        self.onSelect = onSelect
        self.onRemove = onRemove
        self.onCancel = onCancel
        _selectedDate = State(initialValue: currentDate ?? Date())
    }

    var body: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Due Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            HStack {
                if hasExistingDate, let onRemove {
                    Button("Remove Date") {
                        onRemove()
                    }
                    .foregroundStyle(.red)
                    .controlSize(.small)
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .controlSize(.small)

                Button("Confirm") {
                    onSelect(selectedDate)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: DesignTokens.Size.datePopoverWidth)
    }
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
