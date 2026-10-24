// Regenerates every app icon variant from the Songbrook SVG sources.
//
//   swift scripts/generate_app_icons.swift
//
// Requires macOS 13 or later, whose NSImage renders SVG natively.

import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()

func loadSvg(_ relativePath: String) -> NSImage {
  let url = root.appendingPathComponent(relativePath)
  guard let image = NSImage(contentsOf: url) else {
    fatalError("Icon source not found: \(url.path)")
  }
  return image
}

let icon = loadSvg("assets/icons/source/songbrook_icon.svg")
let notificationMark = loadSvg("assets/icons/source/songbrook_notification.svg")

/// Draws `source` into a square bitmap. `rounded` clips to the same corner
/// radius the previous icons used; `opaque` drops the alpha channel, which
/// Apple requires for iOS AppIcon assets (the system applies its own mask).
/// `macGrid` follows Apple's macOS icon grid: an 824/1024 body with a
/// transparent margin, so the system does not frame the icon as legacy art.
func render(
  _ source: NSImage,
  size: Int,
  rounded: Bool = false,
  opaque: Bool = false,
  macGrid: Bool = false
) -> CGImage {
  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
  let alphaInfo: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
  guard
    let context = CGContext(
      data: nil,
      width: size,
      height: size,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: alphaInfo.rawValue
    )
  else {
    fatalError("Could not create a \(size)px bitmap")
  }
  context.interpolationQuality = .high
  context.setShouldAntialias(true)

  var rect = CGRect(x: 0, y: 0, width: size, height: size)
  var radiusFactor: CGFloat = 0.185
  if macGrid {
    let body = CGFloat(size) * 824 / 1024
    rect = rect.insetBy(dx: (CGFloat(size) - body) / 2, dy: (CGFloat(size) - body) / 2)
    radiusFactor = 185.4 / 824
  }
  if rounded {
    let radius = rect.width * radiusFactor
    context.addPath(
      CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    )
    context.clip()
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
  NSGraphicsContext.restoreGraphicsState()

  guard let image = context.makeImage() else {
    fatalError("Could not render a \(size)px icon")
  }
  return image
}

func pngData(_ image: CGImage) -> Data {
  let data = NSMutableData()
  guard
    let destination = CGImageDestinationCreateWithData(
      data, UTType.png.identifier as CFString, 1, nil)
  else {
    fatalError("Could not create a PNG encoder")
  }
  CGImageDestinationAddImage(destination, image, nil)
  guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not encode a PNG")
  }
  return data as Data
}

func write(_ data: Data, to relativePath: String) {
  let url = root.appendingPathComponent(relativePath)
  try! FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  try! data.write(to: url)
}

func savePng(
  _ source: NSImage,
  _ size: Int,
  _ relativePath: String,
  rounded: Bool = false,
  opaque: Bool = false,
  macGrid: Bool = false
) {
  write(
    pngData(render(source, size: size, rounded: rounded, opaque: opaque, macGrid: macGrid)),
    to: relativePath)
}

/// Writes a Windows .ico whose entries are PNG-compressed.
func writeIco(_ source: NSImage, sizes: [Int], to relativePath: String) {
  let images = sizes.map { (size: $0, data: pngData(render(source, size: $0, rounded: true))) }
  var ico = Data()
  func append<T: FixedWidthInteger>(_ value: T) {
    withUnsafeBytes(of: value.littleEndian) { ico.append(contentsOf: $0) }
  }
  append(UInt16(0))
  append(UInt16(1))
  append(UInt16(images.count))
  var offset = 6 + 16 * images.count
  for image in images {
    let sizeByte = UInt8(image.size >= 256 ? 0 : image.size)
    append(sizeByte)
    append(sizeByte)
    append(UInt8(0))
    append(UInt8(0))
    append(UInt16(1))
    append(UInt16(32))
    append(UInt32(image.data.count))
    append(UInt32(offset))
    offset += image.data.count
  }
  for image in images {
    ico.append(image.data)
  }
  write(ico, to: relativePath)
}

// In-app logo.
savePng(icon, 48, "assets/icons/bstream_icon.png", rounded: true)
savePng(icon, 96, "assets/icons/2.0x/bstream_icon.png", rounded: true)
savePng(icon, 144, "assets/icons/3.0x/bstream_icon.png", rounded: true)
savePng(icon, 192, "assets/icons/4.0x/bstream_icon.png", rounded: true)

// Android launcher icons and the white/alpha status-bar icon.
for (directory, size) in [
  ("mipmap-mdpi", 48), ("mipmap-hdpi", 72), ("mipmap-xhdpi", 96),
  ("mipmap-xxhdpi", 144), ("mipmap-xxxhdpi", 192),
] {
  savePng(icon, size, "android/app/src/main/res/\(directory)/ic_launcher.png", rounded: true)
}
savePng(notificationMark, 96, "android/app/src/main/res/drawable-nodpi/ic_stat_bstream_music.png")

// macOS AppIcon.
for size in [16, 32, 64, 128, 256, 512, 1024] {
  savePng(
    icon, size, "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_\(size).png",
    rounded: true, macGrid: true)
}

// iOS AppIcon: square and opaque.
for (name, size) in [
  ("20x20@1x", 20), ("20x20@2x", 40), ("20x20@3x", 60),
  ("29x29@1x", 29), ("29x29@2x", 58), ("29x29@3x", 87),
  ("40x40@1x", 40), ("40x40@2x", 80), ("40x40@3x", 120),
  ("60x60@2x", 120), ("60x60@3x", 180),
  ("76x76@1x", 76), ("76x76@2x", 152), ("83.5x83.5@2x", 167),
  ("1024x1024@1x", 1024),
] {
  savePng(
    icon, size, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-\(name).png",
    opaque: true)
}

// Windows.
writeIco(
  icon, sizes: [16, 20, 24, 32, 40, 48, 64, 80, 96, 128, 256],
  to: "windows/runner/resources/app_icon.ico")

print("Icons written under \(root.path)")
