import AppKit
import Foundation
import CoreText

let projectRoot = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let fontsDir = projectRoot.appendingPathComponent("Resources/Fonts")
let catalogURL = projectRoot.appendingPathComponent("Min/Model/ODRFontCatalog.swift")
let assetsRoot = projectRoot.appendingPathComponent("Min/Assets.xcassets/FontPreviews")

func slug(_ text: String) -> String {
    var hash: UInt64 = 5381
    for b in text.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(b) }
    return String(format: "fp_%016llx", hash)
}

struct Item {
    let fileName: String
    let displayName: String
    let familyName: String
}

let catalog = try String(contentsOf: catalogURL, encoding: .utf8)
let pattern = #"ODRFontItem\(id: \"([^\"]+)\", fileName: \"([^\"]+)\", postScriptName: \"([^\"]+)\", displayName: \"([^\"]+)\", familyName: \"([^\"]+)\", odrTag: \"([^\"]+)\"\)"#
let regex = try NSRegularExpression(pattern: pattern)
let matches = regex.matches(in: catalog, range: NSRange(catalog.startIndex..., in: catalog))
var families: [String: Item] = [:]
for m in matches {
    func g(_ i: Int) -> String { String(catalog[Range(m.range(at: i), in: catalog)!]) }
    let file = g(2), display = g(4), family = g(5)
    // Prefer Regular / 常规 when available
    if let existing = families[family] {
        let prefer = file.lowercased().contains("regular") || display.contains("常规")
        let existingPrefer = existing.fileName.lowercased().contains("regular") || existing.displayName.contains("常规")
        if prefer && !existingPrefer { families[family] = Item(fileName: file, displayName: display, familyName: family) }
    } else {
        families[family] = Item(fileName: file, displayName: display, familyName: family)
    }
}

try? FileManager.default.createDirectory(at: assetsRoot, withIntermediateDirectories: true)

func registerFont(at url: URL) -> String? {
    guard let data = try? Data(contentsOf: url),
          let provider = CGDataProvider(data: data as CFData),
          let cgFont = CGFont(provider) else { return nil }
    var err: Unmanaged<CFError>?
    CTFontManagerRegisterGraphicsFont(cgFont, &err)
    return cgFont.postScriptName as String?
}

func render(text: String, fontURL: URL, pointSize: CGFloat, scale: CGFloat) -> NSImage? {
    guard let ps = registerFont(at: fontURL) else { return nil }
    let font = NSFont(name: ps, size: pointSize) ?? NSFont.systemFont(ofSize: pointSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let attr = NSAttributedString(string: text, attributes: attrs)
    var size = attr.size()
    size.width = ceil(size.width) + 4
    size.height = ceil(size.height) + 4
    guard size.width > 1, size.height > 1 else { return nil }

    let pixel = NSSize(width: size.width * scale, height: size.height * scale)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(pixel.width),
        pixelsHigh: Int(pixel.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.cgContext.clear(CGRect(origin: .zero, size: size))
    attr.draw(at: CGPoint(x: 2, y: 2))
    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: size)
    image.addRepresentation(rep)
    return image
}

var ok = 0, fail = 0
for (family, item) in families.sorted(by: { $0.key < $1.key }) {
    let fontURL = fontsDir.appendingPathComponent(item.fileName)
    guard FileManager.default.fileExists(atPath: fontURL.path) else {
        fputs("missing font: \(item.fileName)\n", stderr)
        fail += 1
        continue
    }
    // Render family display name (not style-specific display name)
    let label = family
    guard let image = render(text: label, fontURL: fontURL, pointSize: 18, scale: 3),
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fputs("render fail: \(family)\n", stderr)
        fail += 1
        continue
    }

    let name = slug(family)
    let setURL = assetsRoot.appendingPathComponent("\(name).imageset")
    try? FileManager.default.createDirectory(at: setURL, withIntermediateDirectories: true)
    let fileName = "\(name)@3x.png"
    try png.write(to: setURL.appendingPathComponent(fileName))
    let contents = """
    {
      "images" : [
        { "idiom" : "universal", "scale" : "1x" },
        { "idiom" : "universal", "scale" : "2x" },
        { "filename" : "\(fileName)", "idiom" : "universal", "scale" : "3x" }
      ],
      "info" : { "author" : "xcode", "version" : 1 }
    }
    """
    try contents.write(to: setURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    print("OK \(family) -> \(name)")
    ok += 1
}

// folder Contents.json
let folderContents = """
{
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "provides-namespace" : true }
}
"""
try folderContents.write(to: assetsRoot.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("done ok=\(ok) fail=\(fail)")
