import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count >= 5 else {
    FileHandle.standardError.write(Data("usage: generate_background.swift <output-path> <title> <width> <height>\n".utf8))
    exit(1)
}

let outputPath = arguments[1]
let title = arguments[2]
guard let width = Int(arguments[3]), let height = Int(arguments[4]), width > 0, height > 0 else {
    FileHandle.standardError.write(Data("width and height must be positive integers\n".utf8))
    exit(1)
}

let canvasSize = NSSize(width: width, height: height)
let backgroundRect = NSRect(origin: .zero, size: canvasSize)
guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
else {
    FileHandle.standardError.write(Data("failed to allocate bitmap buffer\n".utf8))
    exit(1)
}

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    FileHandle.standardError.write(Data("failed to create graphics context\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext
NSGraphicsContext.current?.imageInterpolation = .high
defer { NSGraphicsContext.restoreGraphicsState() }

let gradient = NSGradient(colors: [
    NSColor(calibratedWhite: 1.0, alpha: 0.0),
    NSColor(calibratedWhite: 1.0, alpha: 0.0),
])!
gradient.draw(in: backgroundRect, angle: 0)

let arrow = "\u{2192}" as NSString
let arrowAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 76, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.48, green: 0.55, blue: 0.55, alpha: 0.72)
]
let arrowSize = arrow.size(withAttributes: arrowAttributes)
arrow.draw(
    at: NSPoint(
        x: (CGFloat(width) - arrowSize.width) / 2.0 - 5,
        y: (CGFloat(height) - arrowSize.height) / 2.0 + 37
    ),
    withAttributes: arrowAttributes
)

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to generate PNG data\n".utf8))
    exit(1)
}

try FileManager.default.createDirectory(
    at: URL(fileURLWithPath: outputPath).deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
