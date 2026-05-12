import SwiftUI
import SpriteKit
import AppKit

struct FallingCompletedTaskSnapshot: Identifiable, Equatable {
    let id: String
    let text: String
    let depth: Int
    let sourceFrame: CGRect?

    init(task: TodoTask, sourceFrame: CGRect? = nil) {
        id = task.id
        text = task.displayText
        depth = task.parentTaskId == nil ? 0 : 1
        self.sourceFrame = sourceFrame
    }
}

struct FallingCompletionBurst: Identifiable, Equatable {
    let id = UUID()
    let tasks: [FallingCompletedTaskSnapshot]
}

enum FallingCompletedInitialCanvas {
    static func tasks(from completedTasks: [TodoTask]) -> [FallingCompletedTaskSnapshot] {
        []
    }
}

enum FallingCompletedCanvasState {
    static func bursts(
        _ bursts: [FallingCompletionBurst],
        afterModeChangeFrom oldValue: Bool,
        to newValue: Bool
    ) -> [FallingCompletionBurst] {
        oldValue == newValue ? bursts : []
    }
}

enum FallingCompletedLayout {
    static let completedCardInset: CGFloat = 16
    static let sweepDividerClearance: CGFloat = 16

    static func scenePoint(for sourceFrame: CGRect?, sceneSize: CGSize) -> CGPoint {
        guard let sourceFrame else {
            return CGPoint(
                x: min(72, max(sceneSize.width - 24, 0)),
                y: max(sceneSize.height - 56, 0)
            )
        }

        return CGPoint(
            x: sourceFrame.midX,
            y: max(sceneSize.height - sourceFrame.midY, 0)
        )
    }

    static func letterPositions(
        count: Int,
        sourceFrame: CGRect?,
        sceneSize: CGSize,
        fontSize: CGFloat,
        rowIndex: Int
    ) -> [CGPoint] {
        guard count > 0 else { return [] }

        guard let sourceFrame else {
            let point = scenePoint(for: nil, sceneSize: sceneSize)
            return (0..<count).map { index in
                CGPoint(
                    x: point.x + CGFloat(index) * fontSize * 0.58,
                    y: point.y - CGFloat(rowIndex) * fontSize * 0.8
                )
            }
        }

        let advance = fontSize * 0.58
        let availableWidth = max(sourceFrame.width, advance)
        let textWidth = CGFloat(max(count - 1, 0)) * advance
        let startX = min(sourceFrame.minX, max(sourceFrame.maxX - textWidth, 8))
        let y = max(sceneSize.height - sourceFrame.midY - CGFloat(rowIndex) * fontSize * 0.8, 0)

        return (0..<count).map { index in
            CGPoint(
                x: min(startX + CGFloat(index) * advance, sourceFrame.minX + availableWidth),
                y: y
            )
        }
    }

    static func releaseDelay(sourceIndex: Int, visibleCount: Int, rowIndex: Int) -> Double {
        let rightToLeftIndex = max(visibleCount - sourceIndex - 1, 0)
        return Double(rightToLeftIndex) * 0.018 + Double(rowIndex) * 0.09
    }

    static func physicsBounds(for completedFrame: CGRect?, sceneSize: CGSize, inset: CGFloat) -> CGRect {
        let fallback = CGRect(
            x: inset,
            y: inset,
            width: max(sceneSize.width - inset * 2, 1),
            height: max(sceneSize.height - inset + 180, 1)
        )

        guard let completedFrame, completedFrame.width > 0, completedFrame.height > 0 else {
            return fallback
        }

        let minX = max(completedFrame.minX + inset, 0)
        let maxX = min(completedFrame.maxX - inset, sceneSize.width)
        let cardBottomY = max(sceneSize.height - completedFrame.maxY, 0)
        let floorY = cardBottomY + inset

        return CGRect(
            x: minX,
            y: floorY,
            width: max(maxX - minX, 1),
            height: max(sceneSize.height - floorY + 180, 1)
        )
    }

    static func completedVisibleBounds(for completedFrame: CGRect?, sceneSize: CGSize, inset: CGFloat) -> CGRect {
        let fallback = CGRect(
            x: inset,
            y: inset,
            width: max(sceneSize.width - inset * 2, 1),
            height: max(sceneSize.height - inset * 2, 1)
        )

        guard let completedFrame, completedFrame.width > 0, completedFrame.height > 0 else {
            return fallback
        }

        let minX = max(completedFrame.minX + inset, 0)
        let maxX = min(completedFrame.maxX - inset, sceneSize.width)
        let minY = max(sceneSize.height - completedFrame.maxY + inset, 0)
        let maxY = min(sceneSize.height - completedFrame.minY - inset, sceneSize.height)

        return CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 1),
            height: max(maxY - minY, 1)
        )
    }

    static func sweepTriggerY(
        for dividerFrame: CGRect?,
        sceneSize: CGSize,
        fallbackVisibleBounds: CGRect,
        clearance: CGFloat
    ) -> CGFloat {
        guard let dividerFrame, dividerFrame.width > 0, dividerFrame.height >= 0 else {
            return max(fallbackVisibleBounds.minY, fallbackVisibleBounds.maxY - clearance)
        }

        let dividerY = sceneSize.height - dividerFrame.maxY
        return max(fallbackVisibleBounds.minY, dividerY - clearance)
    }
}

enum FallingCompletedPresentation {
    static let letterTextColor = NSColor(DesignTokens.ColorRole.primaryText)
}

enum FallingCompletedPhysics {
    static let gravity = CGVector(dx: 0, dy: -8.7)
    static let targetPileDensityMultiplier: CGFloat = 1.56
    static let pileDensityScale: CGFloat = 1 / sqrt(targetPileDensityMultiplier)
    static let minimumBodyWidthMultiplier: CGFloat = 0.62
    static let minimumBodyHeightMultiplier: CGFloat = 0.9
    static let settledVelocityThreshold: CGFloat = 80
    static let sweepDuration = 0.55
    static let sweepMinimumDX: CGFloat = 420
    static let sweepMaximumDX: CGFloat = 760
    static let sweepMinimumDY: CGFloat = -80
    static let sweepMaximumDY: CGFloat = 140
    static let sweepAngularVelocity: CGFloat = 7

    static func letterBodySize(for labelSize: CGSize, fontSize: CGFloat) -> CGSize {
        CGSize(
            width: max(labelSize.width, fontSize * minimumBodyWidthMultiplier) * pileDensityScale,
            height: max(labelSize.height, fontSize * minimumBodyHeightMultiplier) * pileDensityScale
        )
    }

    static func shouldSweep(letterFrames: [CGRect], triggerY: CGFloat) -> Bool {
        guard !letterFrames.isEmpty else { return false }
        let highestLetterY = letterFrames.map(\.maxY).max() ?? 0
        return highestLetterY >= triggerY
    }
}

struct FallingCompletedView: NSViewRepresentable {
    let completedTasks: [FallingCompletedTaskSnapshot]
    let bursts: [FallingCompletionBurst]
    let completedFrame: CGRect?
    let completedDividerFrame: CGRect?
    let reduceMotion: Bool
    let density: InterfaceDensity

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60

        let scene = FallingCompletedScene(size: .zero)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        view.presentScene(scene)
        context.coordinator.scene = scene

        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        guard let scene = context.coordinator.scene else { return }
        scene.configure(
            size: nsView.bounds.size,
            density: density,
            completedFrame: completedFrame,
            completedDividerFrame: completedDividerFrame,
            reduceMotion: reduceMotion
        )
        let newBursts = bursts.filter { !context.coordinator.handledBurstIds.contains($0.id) }
        for burst in newBursts {
            scene.emit(burst)
            context.coordinator.handledBurstIds.insert(burst.id)
        }
        scene.syncCompletedTasks(completedTasks)

        let completedTasks = completedTasks
        DispatchQueue.main.async {
            scene.configure(
                size: nsView.bounds.size,
                density: density,
                completedFrame: completedFrame,
                completedDividerFrame: completedDividerFrame,
                reduceMotion: reduceMotion
            )
            scene.syncCompletedTasks(completedTasks)
        }
    }

    final class Coordinator {
        fileprivate weak var scene: FallingCompletedScene?
        var handledBurstIds: Set<UUID> = []
    }
}

fileprivate final class FallingCompletedScene: SKScene {
    private enum PhysicsCategory {
        static let letter: UInt32 = 1 << 0
        static let boundary: UInt32 = 1 << 1
    }

    private var emittedTaskIds: Set<String> = []
    private var reduceMotion = false
    private var density: InterfaceDensity = .regular
    private var randomSeed: UInt64 = 0x5EED
    private var floorY: CGFloat = 34
    private var physicsBounds = CGRect.zero
    private var completedVisibleBounds = CGRect.zero
    private var sweepTriggerY: CGFloat = 0
    private var isSweeping = false

    override init(size: CGSize) {
        super.init(size: size)
        physicsWorld.gravity = FallingCompletedPhysics.gravity
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        physicsWorld.gravity = FallingCompletedPhysics.gravity
    }

    func configure(
        size: CGSize,
        density: InterfaceDensity,
        completedFrame: CGRect?,
        completedDividerFrame: CGRect?,
        reduceMotion: Bool
    ) {
        self.density = density
        self.reduceMotion = reduceMotion
        if self.size != size {
            self.size = size
        }
        let inset = DesignTokens.scaled(FallingCompletedLayout.completedCardInset, in: density)
        physicsBounds = FallingCompletedLayout.physicsBounds(
            for: completedFrame,
            sceneSize: size,
            inset: inset
        )
        completedVisibleBounds = FallingCompletedLayout.completedVisibleBounds(
            for: completedFrame,
            sceneSize: size,
            inset: inset
        )
        sweepTriggerY = FallingCompletedLayout.sweepTriggerY(
            for: completedDividerFrame,
            sceneSize: size,
            fallbackVisibleBounds: completedVisibleBounds,
            clearance: DesignTokens.scaled(FallingCompletedLayout.sweepDividerClearance, in: density)
        )
        floorY = physicsBounds.minY

        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBounds)
        physicsBody?.categoryBitMask = PhysicsCategory.boundary
        physicsBody?.collisionBitMask = PhysicsCategory.letter
        physicsBody?.friction = 0.92
        physicsBody?.restitution = 0.1
        constrainLetterNodesToBounds()
    }

    override func didSimulatePhysics() {
        super.didSimulatePhysics()
        triggerSweepIfNeeded()
    }

    func syncCompletedTasks(_ tasks: [FallingCompletedTaskSnapshot]) {
        let taskIds = Set(tasks.map(\.id))
        for node in children where node.name?.hasPrefix("task:") == true {
            guard let taskId = node.name?.dropFirst("task:".count), !taskIds.contains(String(taskId)) else {
                continue
            }
            node.removeFromParent()
        }
        emittedTaskIds.formIntersection(taskIds)
        trimIfNeeded()
    }

    func emit(_ burst: FallingCompletionBurst) {
        for (index, task) in burst.tasks.enumerated() {
            guard !emittedTaskIds.contains(task.id) else { continue }
            if addTask(
                task,
                rowIndex: index,
                sourceFrame: task.sourceFrame
            ) {
                emittedTaskIds.insert(task.id)
            }
        }
        trimIfNeeded()
    }

    @discardableResult
    private func addTask(
        _ task: FallingCompletedTaskSnapshot,
        rowIndex: Int,
        sourceFrame: CGRect?
    ) -> Bool {
        let characters = Array(task.text)
        guard !characters.isEmpty, size.width > 0, size.height > 0 else { return false }

        let fontSize = DesignTokens.Typography.bodySize(in: density)
        let fallingPositions = FallingCompletedLayout.letterPositions(
            count: characters.count,
            sourceFrame: sourceFrame,
            sceneSize: size,
            fontSize: fontSize,
            rowIndex: rowIndex
        )

        var visibleIndex = 0
        for (sourceIndex, character) in characters.enumerated() {
            if character.isWhitespace {
                continue
            }

            let label = SKLabelNode(text: String(character))
            label.name = "task:\(task.id)"
            label.fontName = "PingFangSC-Regular"
            label.fontSize = fontSize
            label.fontColor = FallingCompletedPresentation.letterTextColor
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zRotation = jitter(max: 0.22)

            let point = fallingPositions[min(sourceIndex, max(fallingPositions.count - 1, 0))]
            label.position = CGPoint(
                x: clampedLetterX(point.x),
                y: max(point.y + jitter(max: 2), floorY + fontSize)
            )

            let bodySize = FallingCompletedPhysics.letterBodySize(for: label.frame.size, fontSize: fontSize)
            label.physicsBody = SKPhysicsBody(rectangleOf: bodySize)
            label.physicsBody?.categoryBitMask = PhysicsCategory.letter
            label.physicsBody?.collisionBitMask = PhysicsCategory.letter | PhysicsCategory.boundary
            label.physicsBody?.contactTestBitMask = 0
            label.physicsBody?.allowsRotation = true
            label.physicsBody?.friction = 0.78
            label.physicsBody?.restitution = 0.08
            label.physicsBody?.linearDamping = 0.34
            label.physicsBody?.angularDamping = 0.42

            label.alpha = 0
            label.physicsBody?.affectedByGravity = false
            addChild(label)
            let delay = FallingCompletedLayout.releaseDelay(
                sourceIndex: sourceIndex,
                visibleCount: characters.count,
                rowIndex: rowIndex
            )
            let release = SKAction.run { [weak label, weak self] in
                guard let label, let self else { return }
                label.physicsBody?.affectedByGravity = true
                label.physicsBody?.velocity = CGVector(
                    dx: self.jitter(max: 32),
                    dy: self.jitter(max: 18)
                )
                label.physicsBody?.angularVelocity = self.jitter(max: 3.2)
            }
            label.run(.sequence([
                .wait(forDuration: delay),
                .fadeAlpha(to: 1, duration: 0.08),
                release
            ]))

            visibleIndex += 1
        }

        return true
    }

    private func triggerSweepIfNeeded() {
        guard !isSweeping, completedVisibleBounds.width > 0, completedVisibleBounds.height > 0 else { return }

        let settledLetterNodes = children.filter { node in
            guard node.name?.hasPrefix("task:") == true else { return false }
            guard node.frame.minY <= completedVisibleBounds.maxY else { return false }
            guard let velocity = node.physicsBody?.velocity else { return true }
            return hypot(velocity.dx, velocity.dy) <= FallingCompletedPhysics.settledVelocityThreshold
        }
        let settledFrames = settledLetterNodes.map(\.frame)
        guard FallingCompletedPhysics.shouldSweep(
            letterFrames: settledFrames,
            triggerY: sweepTriggerY
        ) else { return }

        sweepLetters(settledLetterNodes)
    }

    private func sweepLetters(_ nodes: [SKNode]) {
        guard !nodes.isEmpty else { return }
        isSweeping = true

        let sweepDuration = reduceMotion ? 0.18 : FallingCompletedPhysics.sweepDuration
        for node in nodes {
            node.removeAllActions()

            if reduceMotion {
                node.run(.sequence([
                    .fadeOut(withDuration: sweepDuration),
                    .removeFromParent()
                ]))
                continue
            }

            if let body = node.physicsBody {
                body.affectedByGravity = false
                body.collisionBitMask = 0
                body.contactTestBitMask = 0
                body.velocity = CGVector(
                    dx: random(in: FallingCompletedPhysics.sweepMinimumDX...FallingCompletedPhysics.sweepMaximumDX),
                    dy: random(in: FallingCompletedPhysics.sweepMinimumDY...FallingCompletedPhysics.sweepMaximumDY)
                )
                body.angularVelocity = random(in: -FallingCompletedPhysics.sweepAngularVelocity...FallingCompletedPhysics.sweepAngularVelocity)
            }

            node.run(.sequence([
                .fadeOut(withDuration: sweepDuration),
                .removeFromParent()
            ]))
        }

        run(.sequence([
            .wait(forDuration: sweepDuration + 0.08),
            .run { [weak self] in
                self?.isSweeping = false
            }
        ]))
    }

    private func trimIfNeeded() {
        let maxLetters = 360
        let letterNodes = children.filter { $0.name?.hasPrefix("task:") == true }
        guard letterNodes.count > maxLetters else { return }

        for node in letterNodes.prefix(letterNodes.count - maxLetters) {
            node.run(.sequence([
                .fadeOut(withDuration: 0.18),
                .removeFromParent()
            ]))
        }
    }

    private func constrainLetterNodesToBounds() {
        guard physicsBounds.width > 0 else { return }

        for node in children where node.name?.hasPrefix("task:") == true {
            node.position.x = clampedLetterX(node.position.x)
            node.position.y = max(node.position.y, floorY + node.frame.height / 2)
        }
    }

    private func clampedLetterX(_ x: CGFloat) -> CGFloat {
        let minimumX = max(physicsBounds.minX + 8, 8)
        let maximumX = min(physicsBounds.maxX - 8, size.width - 8)
        guard maximumX >= minimumX else { return minimumX }
        return min(max(x, minimumX), maximumX)
    }

    private func jitter(max amplitude: CGFloat) -> CGFloat {
        randomSeed = randomSeed &* 2862933555777941757 &+ 3037000493
        let normalized = CGFloat((randomSeed >> 33) % 10_000) / 10_000
        return (normalized * 2 - 1) * amplitude
    }

    private func random(in range: ClosedRange<CGFloat>) -> CGFloat {
        randomSeed = randomSeed &* 2862933555777941757 &+ 3037000493
        let normalized = CGFloat((randomSeed >> 33) % 10_000) / 10_000
        return range.lowerBound + (range.upperBound - range.lowerBound) * normalized
    }
}
