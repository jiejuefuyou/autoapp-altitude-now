// AltitudeNow App Icon — 1024x1024 PNG via CoreGraphics.
// Visual: deep teal → emerald gradient sky, two layered mountain silhouettes,
// small white sun above the back peak.

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import AppKit

let outPath = CommandLine.arguments.dropFirst().first ?? "icon.png"
let dim = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!

guard let ctx = CGContext(
    data: nil,
    width: dim, height: dim,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: cs,
    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
) else {
    fatalError("Failed to create CGContext")
}

// 1) Vertical sky gradient (deep blue at top, teal at bottom — Y-axis is up so start at bottom).
let skyColors: CFArray = [
    CGColor(red: 0.16, green: 0.62, blue: 0.56, alpha: 1.0), // bottom — teal
    CGColor(red: 0.10, green: 0.27, blue: 0.32, alpha: 1.0)  // top — deep teal
] as CFArray
let skyGrad = CGGradient(colorsSpace: cs, colors: skyColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(skyGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: dim), options: [])

// 2) Distant white sun.
ctx.setFillColor(CGColor(red: 1, green: 0.94, blue: 0.85, alpha: 0.95))
ctx.fillEllipse(in: CGRect(x: 720, y: 700, width: 120, height: 120))

// 3) Back mountain — soft blue-grey, wider, lower peak.
ctx.setFillColor(CGColor(red: 0.36, green: 0.55, blue: 0.62, alpha: 1.0))
ctx.beginPath()
ctx.move(to: CGPoint(x: 0, y: 380))
ctx.addLine(to: CGPoint(x: 250, y: 600))
ctx.addLine(to: CGPoint(x: 480, y: 480))
ctx.addLine(to: CGPoint(x: 720, y: 720))
ctx.addLine(to: CGPoint(x: 1024, y: 540))
ctx.addLine(to: CGPoint(x: 1024, y: 0))
ctx.addLine(to: CGPoint(x: 0, y: 0))
ctx.closePath()
ctx.fillPath()

// 4) Front mountain — darker, sharper peaks (closer).
ctx.setFillColor(CGColor(red: 0.13, green: 0.25, blue: 0.30, alpha: 1.0))
ctx.beginPath()
ctx.move(to: CGPoint(x: 0, y: 200))
ctx.addLine(to: CGPoint(x: 200, y: 360))
ctx.addLine(to: CGPoint(x: 380, y: 240))
ctx.addLine(to: CGPoint(x: 580, y: 460))
ctx.addLine(to: CGPoint(x: 780, y: 320))
ctx.addLine(to: CGPoint(x: 1024, y: 460))
ctx.addLine(to: CGPoint(x: 1024, y: 0))
ctx.addLine(to: CGPoint(x: 0, y: 0))
ctx.closePath()
ctx.fillPath()

// 5) Snow caps on the front mountain peaks.
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
// Left peak (200, 360)
ctx.beginPath()
ctx.move(to: CGPoint(x: 200, y: 360))
ctx.addLine(to: CGPoint(x: 145, y: 300))
ctx.addLine(to: CGPoint(x: 250, y: 300))
ctx.closePath()
ctx.fillPath()
// Middle peak (580, 460)
ctx.beginPath()
ctx.move(to: CGPoint(x: 580, y: 460))
ctx.addLine(to: CGPoint(x: 510, y: 380))
ctx.addLine(to: CGPoint(x: 650, y: 380))
ctx.closePath()
ctx.fillPath()

// Save.
guard let img = ctx.makeImage() else { fatalError("makeImage failed") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("CGImageDestination failed")
}
CGImageDestinationAddImage(dest, img, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Finalize failed") }
print("wrote \(url.path)")
