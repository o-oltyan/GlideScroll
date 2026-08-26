#!/usr/bin/env swift
// Generates GlideScroll.icns into the given output directory (default: dist).
// Usage: swift Scripts/make-icon.swift [outputDir]
import AppKit

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dist"
let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
let iconsetPath = "\(outputDir)/GlideScroll.iconset"
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let masterSize = 1024.0

func drawMaster() -> NSImage {
    let image = NSImage(size: NSSize(width: masterSize, height: masterSize))
    image.lockFocus()
    defer { image.unlockFocus() }

    let s = masterSize
    // macOS-style icon: rounded rect inset ~10% with ~22.5% corner radius.
    let inset = s * 0.10
    let rect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = rect.width * 0.225
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Background gradient: deep indigo to cyan.
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.22, green: 0.20, blue: 0.65, alpha: 1.0),
        NSColor(calibratedRed: 0.12, green: 0.55, blue: 0.95, alpha: 1.0),
        NSColor(calibratedRed: 0.15, green: 0.80, blue: 0.90, alpha: 1.0),
    ])!
    gradient.draw(in: squircle, angle: -70)

    // Subtle top highlight.
    squircle.addClip()
    let highlight = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.28),
        NSColor.white.withAlphaComponent(0.0),
    ])!
    highlight.draw(in: NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), angle: -90)

    // Mouse glyph with a soft shadow.
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = s * 0.02
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)
    shadow.set()

    guard let symbol = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: 460, weight: .medium))
    else {
        fatalError("computermouse.fill symbol unavailable")
    }
    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    NSColor.white.set()
    let symbolRect = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: symbolRect)
    symbolRect.fill(using: .sourceAtop)
    tinted.unlockFocus()

    let glyphHeight = s * 0.46
    let glyphWidth = glyphHeight * (tinted.size.width / tinted.size.height)
    tinted.draw(
        in: NSRect(x: (s - glyphWidth) / 2, y: s * 0.30, width: glyphWidth, height: glyphHeight),
        from: .zero, operation: .sourceOver, fraction: 1.0
    )

    // Motion waves under the mouse to suggest smooth gliding.
    NSShadow().set()
    let waveColor = NSColor.white.withAlphaComponent(0.85)
    waveColor.setStroke()
    for (index, width) in [0.30, 0.20, 0.11].enumerated() {
        let path = NSBezierPath()
        let y = s * (0.245 - Double(index) * 0.045)
        let waveWidth = s * width
        path.move(to: NSPoint(x: (s - waveWidth) / 2, y: y))
        path.curve(
            to: NSPoint(x: (s + waveWidth) / 2, y: y),
            controlPoint1: NSPoint(x: s / 2 - waveWidth / 6, y: y - s * 0.018),
            controlPoint2: NSPoint(x: s / 2 + waveWidth / 6, y: y + s * 0.018)
        )
        path.lineWidth = s * 0.018
        path.lineCapStyle = .round
        path.stroke()
    }

    return image
}

let master = drawMaster()

func writePNG(_ image: NSImage, pixels: Int, name: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
               from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

for size in [16, 32, 128, 256, 512] {
    writePNG(master, pixels: size, name: "icon_\(size)x\(size)")
    writePNG(master, pixels: size * 2, name: "icon_\(size)x\(size)@2x")
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetPath, "-o", "\(outputDir)/GlideScroll.icns"]
try! iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Wrote \(outputDir)/GlideScroll.icns")
