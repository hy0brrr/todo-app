import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(TodoViewModel.self) private var viewModel
    @Environment(\.interfaceDensity) private var density
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("todoApp.fallingCompletedEnabled") private var fallingCompletedEnabled = false
    @State private var fallingCompletionBursts: [FallingCompletionBurst] = []
    @State private var taskFrames: [String: CGRect] = [:]
    @State private var completedFrame: CGRect?
    @State private var completedDividerFrame: CGRect?

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            backgroundView

            if viewModel.shouldShowLaunchEmptyState {
                LaunchEmptyStateView {
                    viewModel.addPartition()
                }
                .padding(.horizontal, DesignTokens.Spacing.scaledScreenHorizontalInset(in: density))
                .padding(.vertical, DesignTokens.Spacing.scaledScreenVerticalInset(in: density))
            } else {
                GeometryReader { geometry in
                    let topInset = DesignTokens.Spacing.scaledScreenTopInset(in: density)
                    let bottomInset = DesignTokens.Spacing.scaledScreenVerticalInset(in: density)
                    let contentHeight = max(0, geometry.size.height - topInset - bottomInset)
                    let layout = PartitionAreaLayout.calculate(
                        contentHeight: contentHeight,
                        partitionHeights: viewModel.partitions.map(\.height),
                        partitionMinHeight: DesignTokens.Size.scaledPartitionMinHeight(in: density),
                        completedMinHeight: DesignTokens.Size.scaledCompletedMinHeight(in: density),
                        handleGap: DesignTokens.Spacing.scaledCardGap(in: density)
                    )

                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            partitionStack(maxTotalPartitionHeights: layout.maxTotalPartitionHeights)
                                .frame(maxWidth: .infinity)
                                .modifier(
                                    PartitionAreaScrollModifier(
                                        isScrollable: layout.shouldScrollPartitions
                                    )
                                )
                                .frame(height: layout.partitionsAreaHeight)

                            CompletedSectionView(
                                groups: viewModel.completedTaskGroups,
                                showsFallingCompletionCanvas: fallingCompletedEnabled,
                                onSaveTask: { id, rawText in
                                    viewModel.updateTask(id: id, rawText: rawText)
                                },
                                onAddChildTask: { parentId, name in
                                    viewModel.addChildTask(parentTaskId: parentId, rawText: name)
                                },
                                onToggleComplete: completeTask
                            )
                            .frame(height: layout.completedHeight)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: CompletedCardFramePreferenceKey.self,
                                        value: proxy.frame(in: .named(FallingTaskCoordinateSpace.name))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.scaledScreenHorizontalInset(in: density))
                        .padding(.top, topInset)
                        .padding(.bottom, bottomInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                        if fallingCompletedEnabled {
                            let completedTasks = viewModel.completedTasks
                            FallingCompletedView(
                                completedTasks: completedTasks.map { FallingCompletedTaskSnapshot(task: $0) },
                                bursts: fallingCompletionBursts,
                                completedFrame: completedFrame,
                                completedDividerFrame: completedDividerFrame,
                                reduceMotion: reduceMotion,
                                density: density
                            )
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .coordinateSpace(name: FallingTaskCoordinateSpace.name)
                    .onPreferenceChange(TaskItemFramePreferenceKey.self) { frames in
                        taskFrames = frames
                    }
                    .onPreferenceChange(CompletedCardFramePreferenceKey.self) { frame in
                        completedFrame = frame
                    }
                    .onPreferenceChange(CompletedDividerFramePreferenceKey.self) { frame in
                        completedDividerFrame = frame
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .font(DesignTokens.Typography.body(in: density))
        .background(
            WindowChromeController(hoverHeight: DesignTokens.Spacing.windowChromeHoverHeight)
        )
        .frame(
            minWidth: DesignTokens.Size.appMinWidth,
            idealWidth: DesignTokens.Size.appIdealWidth,
            maxWidth: DesignTokens.Size.appMaxWidth,
            minHeight: DesignTokens.Size.appMinHeight
        )
        .sheet(isPresented: $viewModel.showManagePartitions) {
            ManagePartitionsView(
                partitions: $viewModel.partitions,
                onDelete: { viewModel.deletePartition($0) },
                onDismiss: { viewModel.showManagePartitions = false }
            )
        }
        .onChange(of: fallingCompletedEnabled) { oldValue, newValue in
            fallingCompletionBursts = FallingCompletedCanvasState.bursts(
                fallingCompletionBursts,
                afterModeChangeFrom: oldValue,
                to: newValue
            )
        }
    }

    private var backgroundView: some View {
        let shellShape = Rectangle()

        return ZStack {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.clear, in: shellShape)
                    .environment(\.appearsActive, true)

                shellShape
                    .strokeBorder(DesignTokens.ColorRole.shellBorder, lineWidth: 1)
            } else {
                ZStack {
                    WindowGlassBackground()

                    shellShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.ColorRole.shellTintTop,
                                    DesignTokens.ColorRole.shellTintBottom
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    shellShape
                        .strokeBorder(DesignTokens.ColorRole.shellBorder, lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(shellShape)
        .shadow(
            color: .black.opacity(DesignTokens.Shadow.shellOpacity),
            radius: DesignTokens.Shadow.shellRadius,
            y: DesignTokens.Shadow.shellYOffset
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func partitionStack(maxTotalPartitionHeights: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(viewModel.partitions) { partition in
                PartitionView(
                    partition: partition,
                    taskGroups: viewModel.activeTaskGroups(for: partition.id),
                    isEditing: viewModel.editingPartitionId == partition.id,
                    onAddTask: { pid, rawText in
                        viewModel.addTask(partitionId: pid, rawText: rawText)
                    },
                    onAddChildTask: { parentId, name in
                        viewModel.addChildTask(parentTaskId: parentId, rawText: name)
                    },
                    onToggleComplete: completeTask,
                    onToggleStar: { viewModel.toggleStar($0) },
                    onSetDueDate: { id, date in viewModel.setDueDate(id, date: date) },
                    onSaveTask: { id, rawText in
                        viewModel.updateTask(id: id, rawText: rawText)
                    },
                    onSaveEdit: { name in
                        viewModel.savePartitionEdit(id: partition.id, name: name)
                    }
                )
                .frame(height: max(DesignTokens.Size.scaledPartitionMinHeight(in: density), partition.height))
                .clipped()

                PartitionDragHandle { delta in
                    viewModel.resizeBoundary(
                        after: partition.id,
                        delta: delta,
                        maxTotalPartitionHeights: maxTotalPartitionHeights
                    )
                }
                .frame(height: DesignTokens.Spacing.scaledCardGap(in: density))
            }
        }
    }

    private func completeTask(_ taskId: String) {
        let fallingPayload = fallingCompletedEnabled
            ? viewModel.fallingCompletionPayload(for: taskId)
            : []

        viewModel.toggleComplete(taskId)

        guard fallingCompletedEnabled, !fallingPayload.isEmpty else { return }
        fallingCompletionBursts.append(
            FallingCompletionBurst(
                tasks: fallingPayload.map { task in
                    FallingCompletedTaskSnapshot(task: task, sourceFrame: taskFrames[task.id])
                }
            )
        )

        if fallingCompletionBursts.count > 24 {
            fallingCompletionBursts.removeFirst(fallingCompletionBursts.count - 24)
        }
    }
}

private struct CompletedCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect?

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

struct CompletedDividerFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect?

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

struct PartitionAreaLayout {
    let maxTotalPartitionHeights: CGFloat
    let partitionStackHeight: CGFloat
    let completedHeight: CGFloat
    let partitionsAreaHeight: CGFloat
    let shouldScrollPartitions: Bool

    static func calculate(
        contentHeight: CGFloat,
        partitionHeights: [CGFloat],
        partitionMinHeight: CGFloat = DesignTokens.Size.partitionMinHeight,
        completedMinHeight: CGFloat = DesignTokens.Size.completedMinHeight,
        handleGap: CGFloat = DesignTokens.Spacing.cardGap
    ) -> PartitionAreaLayout {
        let totalHandleHeight = CGFloat(partitionHeights.count) * handleGap
        let partitionStackHeight = partitionHeights.reduce(CGFloat.zero) { partialResult, partitionHeight in
            partialResult + max(partitionMinHeight, partitionHeight)
        } + totalHandleHeight
        let maxTotalPartitionHeights = max(
            0,
            contentHeight
                - completedMinHeight
                - totalHandleHeight
        )
        let completedHeight = max(
            completedMinHeight,
            contentHeight - partitionStackHeight
        )
        let partitionsAreaHeight = max(0, contentHeight - completedHeight)

        return PartitionAreaLayout(
            maxTotalPartitionHeights: maxTotalPartitionHeights,
            partitionStackHeight: partitionStackHeight,
            completedHeight: completedHeight,
            partitionsAreaHeight: partitionsAreaHeight,
            shouldScrollPartitions: partitionStackHeight > partitionsAreaHeight
        )
    }
}

private struct LaunchEmptyStateView: View {
    @Environment(\.interfaceDensity) private var density

    let onCreatePartition: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.scaled(24, in: density)) {
            VStack(spacing: DesignTokens.scaled(14, in: density)) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: DesignTokens.scaled(72, in: density), height: DesignTokens.scaled(72, in: density))

                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: DesignTokens.scaled(28, in: density), weight: .semibold))
                        .foregroundStyle(DesignTokens.ColorRole.primaryText.opacity(0.88))
                }

                VStack(spacing: DesignTokens.scaled(8, in: density)) {
                    Text("Start with your first partition")
                        .font(DesignTokens.Typography.screenSubtitle(in: density))
                        .foregroundStyle(DesignTokens.ColorRole.primaryText)

                    Text("Sidebar Todo is ready. Create a partition like Work or Life, then start adding tasks, subtasks, tags, and due dates. Your data now lives in Application Support, so replacing the app won't clear your list.")
                        .font(DesignTokens.Typography.body(in: density))
                        .foregroundStyle(DesignTokens.ColorRole.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: DesignTokens.scaled(420, in: density))
                }
            }

            Button(action: onCreatePartition) {
                Text("Create First Partition")
                    .font(DesignTokens.Typography.bodyMedium(in: density))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.scaled(18, in: density))
                    .padding(.vertical, DesignTokens.scaled(10, in: density))
                    .background(
                        Capsule()
                            .fill(DesignTokens.ColorRole.primaryText)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(emptyStateCard)
    }

    private var emptyStateCard: some View {
        let shape = RoundedRectangle(cornerRadius: DesignTokens.Radius.scaledCard(in: density), style: .continuous)

        return ZStack {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: shape)
                    .environment(\.appearsActive, true)

                shape
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.scaledCardLineWidth(in: density))
            } else {
                shape
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

                shape
                    .strokeBorder(DesignTokens.ColorRole.cardBorder, lineWidth: DesignTokens.Stroke.scaledCardLineWidth(in: density))
            }
        }
        .shadow(
            color: .black.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            y: DesignTokens.Shadow.cardYOffset
        )
    }
}

private struct PartitionAreaScrollModifier: ViewModifier {
    let isScrollable: Bool

    func body(content: Content) -> some View {
        if isScrollable {
            ScrollView {
                content
            }
            .scrollIndicators(.automatic)
        } else {
            content
        }
    }
}

private struct WindowGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .underWindowBackground
        view.state = .active
        view.isEmphasized = false
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.blendingMode = .behindWindow
        nsView.material = .underWindowBackground
        nsView.state = .active
        nsView.isEmphasized = false
    }
}

// MARK: - Partition Drag Handle

struct PartitionDragHandle: View {
    @Environment(\.interfaceDensity) private var density

    let onDrag: (CGFloat) -> Void

    var body: some View {
        PartitionDragHandleView(
            handleHeight: DesignTokens.Size.scaledResizeHandleHeight(in: density),
            onDrag: onDrag
        )
            .frame(maxWidth: .infinity)
    }
}

private struct PartitionDragHandleView: NSViewRepresentable {
    let handleHeight: CGFloat
    let onDrag: (CGFloat) -> Void

    func makeNSView(context: Context) -> PartitionDragHandleNSView {
        let view = PartitionDragHandleNSView()
        view.handleHeight = handleHeight
        view.onDrag = onDrag
        return view
    }

    func updateNSView(_ nsView: PartitionDragHandleNSView, context: Context) {
        nsView.handleHeight = handleHeight
        nsView.onDrag = onDrag
        nsView.updateAppearance()
        nsView.needsLayout = true
    }
}

private final class PartitionDragHandleNSView: NSView {
    var handleHeight: CGFloat = DesignTokens.Size.resizeHandleHeight {
        didSet {
            barLayer.cornerRadius = handleHeight / 2
            needsLayout = true
        }
    }
    var onDrag: (CGFloat) -> Void = { _ in }

    private let barLayer = CALayer()
    private var trackingAreaRef: NSTrackingArea?
    private var isHovering = false {
        didSet { updateAppearance() }
    }
    private var lastDragPointInWindow: CGPoint?

    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        barLayer.cornerRadius = handleHeight / 2
        layer?.addSublayer(barLayer)
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        let barHeight = handleHeight
        barLayer.frame = CGRect(
            x: 0,
            y: (bounds.height - barHeight) / 2,
            width: bounds.width,
            height: barHeight
        )
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaRef = trackingArea
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeUpDown)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    override func mouseDown(with event: NSEvent) {
        lastDragPointInWindow = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let lastDragPointInWindow else { return }
        let currentPointInWindow = event.locationInWindow
        let delta = lastDragPointInWindow.y - currentPointInWindow.y
        onDrag(delta)
        self.lastDragPointInWindow = currentPointInWindow
    }

    override func mouseUp(with event: NSEvent) {
        lastDragPointInWindow = nil
    }

    func updateAppearance() {
        let color = isHovering
            ? NSColor.white.withAlphaComponent(DesignTokens.Opacity.resizeHoverFill)
            : NSColor.clear
        barLayer.backgroundColor = color.cgColor
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(TodoViewModel())
        .frame(width: 400, height: 750)
}
