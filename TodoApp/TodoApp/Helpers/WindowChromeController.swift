import SwiftUI
import AppKit

struct StableVisualEffectMaterialView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let emphasized: Bool

    init(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode,
        state: NSVisualEffectView.State,
        emphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.emphasized = emphasized
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: NSVisualEffectView) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = emphasized
    }
}

struct WindowChromeController: NSViewRepresentable {
    let hoverHeight: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = WindowChromeTrackingView()
        view.hoverHeight = hoverHeight
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let trackingView = nsView as? WindowChromeTrackingView else { return }
        trackingView.hoverHeight = hoverHeight
        trackingView.configureWindowIfNeeded()
    }
}

private final class WindowChromeTrackingView: NSView {
    var hoverHeight: CGFloat = 52
    private var showsTrafficLights = false
    private var hoverTimer: Timer?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindowIfNeeded()
        startHoverTimerIfNeeded()
        refreshHoverState(animated: false)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            stopHoverTimer()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    deinit {
        stopHoverTimer()
    }

    override func layout() {
        super.layout()
        configureWindowIfNeeded()
    }

    func configureWindowIfNeeded() {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        if #available(macOS 11.0, *) {
            window.titlebarSeparatorStyle = .none
        }
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        clearTrafficLightBackgrounds()
        applyTrafficLights(animated: false)
    }

    private func clearTrafficLightBackgrounds() {
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        for type in buttons {
            guard let button = window?.standardWindowButton(type) else { continue }
            let candidateViews = [button.superview, button.superview?.superview]
            for candidate in candidateViews {
                candidate?.wantsLayer = true
                candidate?.layer?.backgroundColor = NSColor.clear.cgColor
            }
        }
    }

    private func startHoverTimerIfNeeded() {
        guard hoverTimer == nil else { return }
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.refreshHoverState(animated: true)
        }
        RunLoop.main.add(hoverTimer!, forMode: .common)
    }

    private func stopHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    private func refreshHoverState(animated: Bool) {
        guard let window else {
            setTrafficLightsVisible(false, animated: animated)
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let titlebarHeight = window.frame.height - window.contentLayoutRect.height
        let totalHoverHeight = hoverHeight + max(titlebarHeight, 0)
        let isInsideWindow = window.frame.contains(mouseLocation)
        let isInsideTopZone = isInsideWindow && mouseLocation.y >= window.frame.maxY - totalHoverHeight
        setTrafficLightsVisible(isInsideTopZone, animated: animated)
    }

    private func setTrafficLightsVisible(_ visible: Bool, animated: Bool) {
        guard showsTrafficLights != visible else { return }
        showsTrafficLights = visible
        applyTrafficLights(animated: animated)
    }

    private func applyTrafficLights(animated: Bool) {
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        for type in buttons {
            guard let button = window?.standardWindowButton(type) else { continue }
            button.isHidden = false
            button.isEnabled = showsTrafficLights

            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.16
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    button.animator().alphaValue = showsTrafficLights ? 1 : 0
                }
            } else {
                button.alphaValue = showsTrafficLights ? 1 : 0
            }
        }
    }
}
