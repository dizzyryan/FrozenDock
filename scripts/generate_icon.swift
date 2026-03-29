#!/usr/bin/env swift

import Cocoa

// Generate FrozenDock app icons at all required sizes
// Run: swift scripts/generate_icon.swift

let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

func drawIcon(size: Int) -> NSBitmapImageRep {
    let s = CGFloat(size)
    let rep = NSBitmapImageRep(
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
    )!
    rep.size = NSSize(width: size, height: size)

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let gc = ctx.cgContext

    // Background: rounded rect with gradient
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient: deep blue to cyan
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.10, green: 0.15, blue: 0.35, alpha: 1.0),
        CGColor(red: 0.15, green: 0.40, blue: 0.70, alpha: 1.0),
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!

    gc.saveGState()
    gc.addPath(bgPath)
    gc.clip()
    gc.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    gc.restoreGState()

    // Draw snowflake symbol
    let center = CGPoint(x: s / 2, y: s / 2)
    let armLength = s * 0.28
    let lineWidth = s * 0.045
    let branchLen = s * 0.09
    let branchOffset = s * 0.12

    gc.setStrokeColor(CGColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0))
    gc.setLineCap(.round)
    gc.setLineWidth(lineWidth)

    // 6 arms at 60-degree intervals
    for i in 0..<6 {
        let angle = CGFloat(i) * .pi / 3.0 - .pi / 2.0

        let endX = center.x + armLength * cos(angle)
        let endY = center.y + armLength * sin(angle)

        // Main arm
        gc.move(to: center)
        gc.addLine(to: CGPoint(x: endX, y: endY))
        gc.strokePath()

        // Branches
        let branchBase = CGPoint(
            x: center.x + branchOffset * cos(angle),
            y: center.y + branchOffset * sin(angle)
        )

        for sign: CGFloat in [-1, 1] {
            let branchAngle = angle + sign * .pi / 3.0
            let bEnd = CGPoint(
                x: branchBase.x + branchLen * cos(branchAngle),
                y: branchBase.y + branchLen * sin(branchAngle)
            )
            gc.move(to: branchBase)
            gc.addLine(to: bEnd)
            gc.strokePath()
        }
    }

    // Center dot
    let dotRadius = s * 0.04
    gc.setFillColor(CGColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0))
    gc.fillEllipse(in: CGRect(
        x: center.x - dotRadius, y: center.y - dotRadius,
        width: dotRadius * 2, height: dotRadius * 2
    ))

    // Small dock bar at bottom
    let dockHeight = s * 0.06
    let dockWidth = s * 0.50
    let dockX = (s - dockWidth) / 2
    let dockY = s * 0.10
    let dockRect = CGRect(x: dockX, y: dockY, width: dockWidth, height: dockHeight)
    let dockPath = CGPath(roundedRect: dockRect, cornerWidth: dockHeight / 2, cornerHeight: dockHeight / 2, transform: nil)

    gc.setFillColor(CGColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.6))
    gc.addPath(dockPath)
    gc.fillPath()

    NSGraphicsContext.current = nil
    return rep
}

// Output directory
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let projectDir = scriptDir.deletingLastPathComponent()
let iconsetDir = projectDir
    .appendingPathComponent("FrozenDock/Resources/Assets.xcassets/AppIcon.appiconset")

let fm = FileManager.default
try? fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

// Generate icons
for (size, filename) in sizes {
    let bitmap = drawIcon(size: size)
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(filename)")
        continue
    }
    let filePath = iconsetDir.appendingPathComponent(filename)
    try pngData.write(to: filePath)
    print("Generated \(filename) (\(size)x\(size) px)")
}

// Update Contents.json
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = iconsetDir.appendingPathComponent("Contents.json")
try contentsJSON.write(to: contentsPath, atomically: true, encoding: .utf8)
print("Updated Contents.json")
print("Done! Icon set generated at: \(iconsetDir.path)")
