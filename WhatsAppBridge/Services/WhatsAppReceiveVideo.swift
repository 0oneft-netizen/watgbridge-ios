import AVFoundation
import CoreMedia
import QuartzCore
import UIKit

// Receive-only H.264 renderer. It never accesses the iPhone camera.
@MainActor
final class WhatsAppReceiveVideo {
    let layer = AVSampleBufferDisplayLayer()
    private var sps: Data?
    private var pps: Data?
    private var format: CMVideoFormatDescription?
    private var needsKeyframe = true
    private var displayBounds: CGRect = .zero
    private var orientation = 0

    init() {
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = UIColor.black.cgColor
    }
    func setDisplayBounds(_ bounds: CGRect) {
        displayBounds = bounds
        layoutVideo()
    }
    func setOrientation(_ turns: Int) {
        guard (0...3).contains(turns) else { return }
        orientation = turns
        layoutVideo()
    }
    private func layoutVideo() {
        let rotated = orientation % 2 != 0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.bounds = CGRect(origin: .zero, size: rotated
            ? CGSize(width: displayBounds.height, height: displayBounds.width)
            : displayBounds.size)
        layer.position = CGPoint(x: displayBounds.midX, y: displayBounds.midY)
        layer.setAffineTransform(CGAffineTransform(rotationAngle: -CGFloat(orientation) * .pi / 2))
        CATransaction.commit()
    }
    func stop() {
        orientation = 0; layoutVideo()
        layer.flushAndRemoveImage(); sps = nil; pps = nil; format = nil; needsKeyframe = true
    }
    func receive(_ data: Data) -> Bool {
        guard !data.isEmpty, data.count <= 1024 * 1024 else { return false }
        let units = annexB(data)
        var pictures: [Data] = []
        var keyframe = false
        var hasSlice = false
        for unit in units {
            guard let byte = unit.first else { continue }
            switch byte & 0x1f {
            case 7:
                if sps != unit { sps = unit; format = nil; needsKeyframe = true }
            case 8:
                if pps != unit { pps = unit; format = nil; needsKeyframe = true }
            case 5: keyframe = true; hasSlice = true; pictures.append(unit)
            case 1: hasSlice = true; pictures.append(unit)
            case 6: pictures.append(unit)
            default: break
            }
        }
        guard hasSlice else { return false }
        if format == nil { updateFormat() }
        guard let format, !needsKeyframe || keyframe else { return false }
        if layer.status == .failed { layer.flush(); needsKeyframe = true }
        guard !needsKeyframe || keyframe, layer.isReadyForMoreMediaData else { return false }
        var packed = Data()
        for unit in pictures {
            var length = UInt32(unit.count).bigEndian
            withUnsafeBytes(of: &length) { packed.append(contentsOf: $0) }
            packed.append(unit)
        }
        var block: CMBlockBuffer?
        guard CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
            memoryBlock: nil, blockLength: packed.count, blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil, offsetToData: 0, dataLength: packed.count,
            flags: 0, blockBufferOut: &block) == kCMBlockBufferNoErr,
            let block else { return false }
        let copied = packed.withUnsafeBytes { bytes -> OSStatus in
            guard let address = bytes.baseAddress else { return -1 }
            return CMBlockBufferReplaceDataBytes(with: address, blockBuffer: block, offsetIntoDestination: 0, dataLength: packed.count)
        }
        guard copied == kCMBlockBufferNoErr else { return false }
        var timing = CMSampleTimingInfo(duration: .invalid,
            presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600),
            decodeTimeStamp: .invalid)
        var size = packed.count
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: block,
            formatDescription: format, sampleCount: 1, sampleTimingEntryCount: 1,
            sampleTimingArray: &timing, sampleSizeEntryCount: 1, sampleSizeArray: &size,
            sampleBufferOut: &sample) == noErr, let sample else { return false }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(dictionary,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        layer.enqueue(sample)
        needsKeyframe = false
        return true
    }
    private func updateFormat() {
        guard let sps, let pps, sps.count >= 4, !pps.isEmpty else { return }
        sps.withUnsafeBytes { first in
            pps.withUnsafeBytes { second in
                guard let a = first.bindMemory(to: UInt8.self).baseAddress,
                      let b = second.bindMemory(to: UInt8.self).baseAddress else { return }
                let pointers = [a, b]
                let sizes = [sps.count, pps.count]
                pointers.withUnsafeBufferPointer { pointer in
                    sizes.withUnsafeBufferPointer { size in
                        guard let pointer = pointer.baseAddress, let size = size.baseAddress else { return }
                        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                            parameterSetCount: 2, parameterSetPointers: pointer, parameterSetSizes: size,
                            nalUnitHeaderLength: 4, formatDescriptionOut: &format)
                        if status != noErr { format = nil }
                    }
                }
            }
        }
    }
    private func annexB(_ data: Data) -> [Data] {
        let bytes = [UInt8](data)
        var starts: [(Int, Int)] = []
        var index = 0
        while index + 2 < bytes.count {
            if bytes[index] == 0, bytes[index + 1] == 0 {
                if bytes[index + 2] == 1 { starts.append((index, 3)); index += 3; continue }
                if index + 3 < bytes.count, bytes[index + 2] == 0, bytes[index + 3] == 1 {
                    starts.append((index, 4)); index += 4; continue
                }
            }
            index += 1
        }
        return starts.enumerated().compactMap { position, start in
            let end = position + 1 < starts.count ? starts[position + 1].0 : bytes.count
            let beginning = start.0 + start.1
            guard beginning < end else { return nil }
            return Data(bytes[beginning..<end])
        }
    }
}
