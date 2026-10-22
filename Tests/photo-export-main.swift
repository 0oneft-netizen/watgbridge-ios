import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

func require(_ value: @autoclosure () -> Bool, _ message: String) {
    if !value() { fatalError(message) }
}
func rejected(_ label: String, _ body: () throws -> Void) {
    do { try body(); fatalError("Expected rejection: \(label)") } catch { print("PASS:", label) }
}
func fixtureImage() -> CGImage {
    let ctx = CGContext(data: nil, width: 12, height: 8, bitsPerComponent: 8, bytesPerRow: 48,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 12, height: 8))
    ctx.clear(CGRect(x: 0, y: 0, width: 3, height: 3))
    return ctx.makeImage()!
}
func encoded(_ type: UTType, frames: Int = 1, orientation: Int = 1) -> Data {
    let data = CFDataCreateMutable(nil, 0)!
    let output = CGImageDestinationCreateWithData(data, type.identifier as CFString, frames, nil)!
    for _ in 0..<frames {
        CGImageDestinationAddImage(output, fixtureImage(), [kCGImagePropertyOrientation: orientation] as CFDictionary)
    }
    require(CGImageDestinationFinalize(output), "Fixture encoding failed: \(type)")
    return data as Data
}
func runTests() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let jpeg = encoded(.jpeg, orientation: 6)
    let jfif = directory.appendingPathComponent("photo.JFIF")
    try jpeg.write(to: jfif)
    let prepared = try PhotoExportEncoder.prepare(file: jfif)
    require(prepared.data == jpeg, "JPEG must not be recompressed")
    require(prepared.typeIdentifier == UTType.jpeg.identifier && prepared.fileExtension == "jpg", "JFIF must export as explicit JPEG")
    let jpegSource = CGImageSourceCreateWithData(prepared.data as CFData, nil)!
    let properties = CGImageSourceCopyPropertiesAtIndex(jpegSource, 0, nil)! as NSDictionary
    require((properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue == 6, "JPEG orientation was lost")
    print("PASS: JFIF identified from bytes; JPEG pixels/data and EXIF orientation preserved")

    let wrongExtension = directory.appendingPathComponent("image.bin")
    let png = encoded(.png)
    try png.write(to: wrongExtension)
    let p = try PhotoExportEncoder.prepare(file: wrongExtension)
    require(p.data == png && p.fileExtension == "png", "PNG/alpha must remain lossless despite wrong filename")
    print("PASS: filename does not override PNG content; original alpha-capable data preserved")

    let gif = encoded(.gif, frames: 2)
    let animated = try PhotoExportEncoder.prepare(data: gif)
    require(animated.data == gif && animated.fileExtension == "gif", "GIF data changed")
    require(CGImageSourceGetCount(CGImageSourceCreateWithData(animated.data as CFData, nil)!) == 2, "Animation lost")
    print("PASS: animated GIF frames preserved")

    let tiff = encoded(.tiff, orientation: 6)
    let converted = try PhotoExportEncoder.prepare(data: tiff)
    require(converted.fileExtension == "png" && converted.typeIdentifier == UTType.png.identifier, "Fallback must be PNG")
    let result = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(converted.data as CFData, nil)!, 0, nil)!
    require(result.width == 8 && result.height == 12, "Fallback rotated or resized incorrectly")
    print("PASS: fallback PNG keeps full dimensions and applies orientation")

    rejected("HTML/login response is not imported as a photo") { _ = try PhotoExportEncoder.prepare(data: Data("<html>Login required</html>".utf8)) }
    rejected("empty image is rejected") { _ = try PhotoExportEncoder.prepare(data: Data()) }
    rejected("truncated JPEG is rejected") { _ = try PhotoExportEncoder.prepare(data: jpeg.prefix(20)) }
    rejected("missing file is rejected") { _ = try PhotoExportEncoder.prepare(file: directory.appendingPathComponent("missing.jpg")) }
    rejected("directory is not an image file") { _ = try PhotoExportEncoder.prepare(file: directory) }
    print("PHOTO EXPORT: all 9 native ImageIO scenarios passed")
}
do { try runTests() } catch { fatalError("Photo export tests failed: \(error)") }
