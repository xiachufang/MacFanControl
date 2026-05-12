#!/usr/bin/env swift
// Render an app icon from the SF Symbol "fanblades" onto a rounded gradient square.
// Produces a single 1024×1024 PNG; the surrounding shell script downscales to the
// other sizes and writes the appiconset Contents.json.
//
// Usage: swift Tools/generate-app-icon.swift <out.png>

import AppKit

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: generate-app-icon.swift <out.png>\n", stderr); exit(1)
}
let outPath = CommandLine.arguments[1]
let size: CGFloat = 1024

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let bg = NSGradient(colors: [
    NSColor(srgbRed: 0.18, green: 0.55, blue: 0.96, alpha: 1),
    NSColor(srgbRed: 0.06, green: 0.27, blue: 0.62, alpha: 1)
])!
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.225, yRadius: size * 0.225)
bg.draw(in: path, angle: 270)

let symbolPoint = size * 0.62
let cfg = NSImage.SymbolConfiguration(pointSize: symbolPoint, weight: .regular)
guard let fan = NSImage(systemSymbolName: "fanblades", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) else {
    fputs("SF Symbol fanblades not available\n", stderr); exit(2)
}

NSColor.white.set()
let fanRect = NSRect(
    x: (size - fan.size.width) / 2,
    y: (size - fan.size.height) / 2,
    width: fan.size.width,
    height: fan.size.height
)
fan.draw(in: fanRect, from: .zero, operation: .sourceOver, fraction: 1)
fanRect.fill(using: .sourceAtop)

image.unlockFocus()

guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("cgImage failed\n", stderr); exit(3)
}
let rep = NSBitmapImageRep(cgImage: cg)
guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("png encoding failed\n", stderr); exit(4)
}
try png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) (\(png.count) bytes)")
