import AppKit
import Foundation

struct PixelRect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let color: NSColor
}

enum IconBuilderError: Error {
    case invalidBitmapSize(Int)
    case missingBitmapRepresentation(Int)
    case pngEncodingFailed(Int)
    case iconutilFailed(Int32)
}

private let gridSize = 16

private let background = NSColor(calibratedRed: 0.863, green: 0.902, blue: 0.925, alpha: 1)
private let frameDark = NSColor(calibratedRed: 0.059, green: 0.090, blue: 0.165, alpha: 1)
private let frame = NSColor(calibratedRed: 0.200, green: 0.271, blue: 0.333, alpha: 1)
private let screen = NSColor(calibratedRed: 0.055, green: 0.169, blue: 0.129, alpha: 1)
private let green = NSColor(calibratedRed: 0.204, green: 0.827, blue: 0.600, alpha: 1)
private let greenDim = NSColor(calibratedRed: 0.063, green: 0.725, blue: 0.506, alpha: 1)
private let amber = NSColor(calibratedRed: 0.961, green: 0.620, blue: 0.043, alpha: 1)

private let appIconPixels: [PixelRect] = [
    PixelRect(x: 0, y: 0, width: 16, height: 16, color: background),
    PixelRect(x: 2, y: 3, width: 12, height: 8, color: frameDark),
    PixelRect(x: 3, y: 4, width: 10, height: 6, color: frame),
    PixelRect(x: 4, y: 5, width: 8, height: 4, color: screen),
    PixelRect(x: 5, y: 6, width: 1, height: 1, color: green),
    PixelRect(x: 6, y: 6, width: 1, height: 1, color: green),
    PixelRect(x: 7, y: 6, width: 1, height: 1, color: greenDim),
    PixelRect(x: 8, y: 6, width: 1, height: 1, color: greenDim),
    PixelRect(x: 5, y: 7, width: 4, height: 1, color: green),
    PixelRect(x: 5, y: 8, width: 2, height: 1, color: greenDim),
    PixelRect(x: 7, y: 8, width: 3, height: 1, color: green),
    PixelRect(x: 12, y: 4, width: 1, height: 1, color: amber),
    PixelRect(x: 6, y: 11, width: 4, height: 1, color: frame),
    PixelRect(x: 5, y: 12, width: 6, height: 1, color: frameDark)
]

private let iconSetEntries: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

private let fileManager = FileManager.default
private let scriptURL = URL(fileURLWithPath: #filePath)
private let rootURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
private let resourcesURL = rootURL.appendingPathComponent("Resources", isDirectory: true)
private let iconSetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
private let iconFileURL = resourcesURL.appendingPathComponent("AppIcon.icns")
private let previewURL = resourcesURL.appendingPathComponent("AppIcon-preview.png")

func draw(rects: [PixelRect], in context: NSGraphicsContext, size: Int) throws {
    guard size % gridSize == 0 else {
        throw IconBuilderError.invalidBitmapSize(size)
    }

    context.imageInterpolation = .none
    let unit = CGFloat(size / gridSize)
    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    for rect in rects {
        rect.color.setFill()
        let drawRect = NSRect(
            x: CGFloat(rect.x) * unit,
            y: CGFloat(gridSize - rect.y - rect.height) * unit,
            width: CGFloat(rect.width) * unit,
            height: CGFloat(rect.height) * unit
        )
        NSBezierPath(rect: drawRect).fill()
    }
}

func makePNG(size: Int, destination: URL) throws {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )

    guard let bitmap else {
        throw IconBuilderError.missingBitmapRepresentation(size)
    }

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw IconBuilderError.missingBitmapRepresentation(size)
    }
    NSGraphicsContext.current = context
    try draw(rects: appIconPixels, in: context, size: size)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconBuilderError.pngEncodingFailed(size)
    }

    try data.write(to: destination)
}

func recreateIconSetDirectory() throws {
    if fileManager.fileExists(atPath: iconSetURL.path) {
        try fileManager.removeItem(at: iconSetURL)
    }

    try fileManager.createDirectory(at: iconSetURL, withIntermediateDirectories: true)
}

func buildIcns() throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconSetURL.path, "-o", iconFileURL.path]

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw IconBuilderError.iconutilFailed(process.terminationStatus)
    }
}

do {
    try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
    try recreateIconSetDirectory()

    for entry in iconSetEntries {
        try makePNG(size: entry.size, destination: iconSetURL.appendingPathComponent(entry.name))
    }

    try makePNG(size: 512, destination: previewURL)
    try buildIcns()

    print("Generated iconset: \(iconSetURL.path)")
    print("Generated icns: \(iconFileURL.path)")
    print("Generated preview: \(previewURL.path)")
} catch {
    fputs("generate-icons failed: \(error)\n", stderr)
    exit(1)
}
