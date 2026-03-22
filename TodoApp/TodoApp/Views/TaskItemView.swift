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
    @State private var isHoveringDueDate = false

    @FocusState private var isNameFieldFocused: Bool
    @State private var clickHandler = ClickOutsideHandler()

    var body: some View {
        HStack(spacing: 8) {
            // Completion checkbox
            Button {
                onToggleComplete(task.id)
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted
                                ? Color.gray
                                : (isHoveringCheckbox ? Color.blue : Color.gray.opacity(0.5)),
                            lineWidth: 1.5
                        )
                        .frame(width: 14, height: 14)
                        .background(
                            Circle()
                                .fill(task.isCompleted ? Color.gray : Color.clear)
                        )
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .scaleEffect(isHoveringCheckbox ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHoveringCheckbox)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringCheckbox = $0 }

            // Task name — double-click to edit, click outside to save
            if isEditing {
                TextField("Task name", text: $editingName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
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
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
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
                    // Task HAS a due date
                    if isHovering || showDatePicker {
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Text(DateHelpers.formatDueDate(dueDate))
                                .font(.system(size: 10))
                                .foregroundStyle(
                                    isHoveringDueDate
                                        ? .blue
                                        : (DateHelpers.isOverdue(dueDate) ? .red : .blue)
                                )
                                .fontWeight(.medium)
                                .underline()
                                .scaleEffect(isHoveringDueDate ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: isHoveringDueDate)
                        }
                        .buttonStyle(.plain)
                        .onHover { isHoveringDueDate = $0 }
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
                        Text(DateHelpers.formatDueDate(dueDate))
                            .font(.system(size: 10))
                            .foregroundStyle(DateHelpers.isOverdue(dueDate) ? .red : .secondary)
                            .fontWeight(DateHelpers.isOverdue(dueDate) ? .medium : .regular)
                    }
                } else {
                    // Task has NO due date — calendar icon with hover effect
                    Button {
                        showDatePicker.toggle()
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(isHoveringCalendar ? .blue : .secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                            .scaleEffect(isHoveringCalendar ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringCalendar)
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

                // Star button with hover effect
                Button {
                    onToggleStar(task.id)
                } label: {
                    Image(systemName: task.isStarred ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .foregroundStyle(
                            task.isStarred
                                ? (isHoveringStar ? .orange : .yellow)
                                : (isHoveringStar ? .yellow : .secondary.opacity(isHovering ? 1 : 0))
                        )
                        .scaleEffect(isHoveringStar ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isHoveringStar)
                }
                .buttonStyle(.plain)
                .onHover { isHoveringStar = $0 }
            } else if task.isStarred {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.primary.opacity(0.04) : Color.clear)
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
        .frame(width: 280)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "Task with due date", isStarred: true, dueDate: Date()),
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in },
            onRename: { _, _ in }
        )
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "Task without due date"),
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in },
            onRename: { _, _ in }
        )
        TaskItemView(
            task: TodoTask(partitionId: "p1", name: "Completed task", isCompleted: true),
            onToggleComplete: { _ in },
            onToggleStar: { _ in },
            onSetDueDate: { _, _ in },
            onRename: { _, _ in }
        )
    }
    .padding()
    .frame(width: 350)
}
