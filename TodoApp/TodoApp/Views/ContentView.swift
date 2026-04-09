import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(TodoViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            backgroundView

            GeometryReader { geometry in
                let topInset = DesignTokens.Spacing.screenTopInset
                let bottomInset = DesignTokens.Spacing.screenVerticalInset
                let totalHandleHeight = CGFloat(viewModel.partitions.count) * DesignTokens.Spacing.cardGap
                let contentHeight = max(0, geometry.size.height - topInset - bottomInset)
                let minimumPartitionStackHeight = CGFloat(viewModel.partitions.count)
                    * DesignTokens.Size.partitionMinHeight
                    + totalHandleHeight
                let maxTotalPartitionHeights = max(
                    0,
                    contentHeight
                        - DesignTokens.Size.completedMinHeight
                        - totalHandleHeight
                )
                let partitionStackHeight = totalPartitionHeight
                let completedHeight = max(
                    DesignTokens.Size.completedMinHeight,
                    contentHeight - partitionStackHeight
                )
                let partitionsAreaHeight = max(0, contentHeight - completedHeight)
                let shouldScrollPartitions = minimumPartitionStackHeight > partitionsAreaHeight

                VStack(spacing: 0) {
                    partitionStack(maxTotalPartitionHeights: maxTotalPartitionHeights)
                        .frame(maxWidth: .infinity)
                        .modifier(
                            PartitionAreaScrollModifier(
                                isScrollable: shouldScrollPartitions
                            )
                        )
                        .frame(height: partitionsAreaHeight)

                    CompletedSectionView(
                        tasks: viewModel.completedTasks,
                        onToggleComplete: { viewModel.toggleComplete($0) }
                    )
                    .frame(height: completedHeight)
                }
                .padding(.horizontal, DesignTokens.Spacing.screenHorizontalInset)
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .font(DesignTokens.Typography.body)
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
    }

    private var totalPartitionHeight: CGFloat {
        let partitionHeights = viewModel.partitions.reduce(CGFloat.zero) { partialResult, partition in
            partialResult + max(DesignTokens.Size.partitionMinHeight, partition.height)
        }
        let handleHeights = CGFloat(viewModel.partitions.count) * DesignTokens.Spacing.cardGap
        return partitionHeights + handleHeights
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
                    tasks: viewModel.activeTasks(for: partition.id),
                    isEditing: viewModel.editingPartitionId == partition.id,
                    onAddTask: { pid, name in viewModel.addTask(partitionId: pid, name: name) },
                    onToggleComplete: { viewModel.toggleComplete($0) },
                    onToggleStar: { viewModel.toggleStar($0) },
                    onSetDueDate: { id, date in viewModel.setDueDate(id, date: date) },
                    onRename: { id, name in viewModel.renameTask(id, name: name) },
                    onStartEdit: { viewModel.editingPartitionId = partition.id },
                    onSaveEdit: { name, color in
                        viewModel.savePartitionEdit(id: partition.id, name: name, color: color)
                    }
                )
                .frame(height: max(DesignTokens.Size.partitionMinHeight, partition.height))
                .clipped()

                PartitionDragHandle { delta in
                    viewModel.resizeBoundary(
                        after: partition.id,
                        delta: delta,
                        maxTotalPartitionHeights: maxTotalPartitionHeights
                    )
                }
                .frame(height: DesignTokens.Spacing.cardGap)
            }
        }
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
    let onDrag: (CGFloat) -> Void

    var body: some View {
        PartitionDragHandleView(onDrag: onDrag)
            .frame(maxWidth: .infinity)
    }
}

private struct PartitionDragHandleView: NSViewRepresentable {
    let onDrag: (CGFloat) -> Void

    func makeNSView(context: Context) -> PartitionDragHandleNSView {
        let view = PartitionDragHandleNSView()
        view.onDrag = onDrag
        return view
    }

    func updateNSView(_ nsView: PartitionDragHandleNSView, context: Context) {
        nsView.onDrag = onDrag
        nsView.updateAppearance()
    }
}

private final class PartitionDragHandleNSView: NSView {
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
        barLayer.cornerRadius = DesignTokens.Size.resizeHandleHeight / 2
        layer?.addSublayer(barLayer)
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        let barHeight = DesignTokens.Size.resizeHandleHeight
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
