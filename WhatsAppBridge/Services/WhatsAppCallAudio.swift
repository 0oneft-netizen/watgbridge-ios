import AVFoundation
import Foundation

// Audio-only engine. No camera capture or outbound video exists in this class.
struct WhatsAppAudioMetrics: Sendable {
    let running: Bool
    let transmitting: Bool
    let muted: Bool
    let taps: Int
    let converted: Int
    let conversionErrors: Int
    let produced: Int
    let received: Int
    let played: Int
    let capturePeak: Float
    let receivePeak: Float
    let inputRate: Double
}

final class WhatsAppCallAudio {
    private let queue = DispatchQueue(label: "bridge.call.audio", qos: .userInteractive)
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    // Keep input in the rendering graph while preventing local microphone echo.
    private let captureMixer = AVAudioMixerNode()
    private var taps = 0
    private var converted = 0
    private var conversionErrors = 0
    private var produced = 0
    private var received = 0
    private var played = 0
    private var capturePeak: Float = 0
    private var receivePeak: Float = 0
    private var inputRate: Double = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
    private var converter: AVAudioConverter?
    private var samples: [Float] = []
    private var running = false
    private var transmitting = false
    private var muted = false
    private var playbackPending = 0
    private var generation = 0
    private var tapped = false
    private var attached = false
    private var onFrame: ((Data) -> Void)?

    func start(speaker: Bool, onFrame: @escaping (Data) -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
                    try session.setPreferredSampleRate(48000)
                    try session.setPreferredIOBufferDuration(0.02)
                    try session.setActive(true)
                    try session.overrideOutputAudioPort(speaker ? .speaker : .none)
                    // Enable Apple's echo cancellation before starting the engine.
                    try self.engine.inputNode.setVoiceProcessingEnabled(true)
                    let inputFormat = self.engine.inputNode.outputFormat(forBus: 0)
                    guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0,
                          let converter = AVAudioConverter(from: inputFormat, to: self.format) else {
                        throw URLError(.cannotDecodeContentData)
                    }
                    self.converter = converter
                    self.onFrame = onFrame
                    self.inputRate = inputFormat.sampleRate
                    self.engine.attach(self.captureMixer)
                    self.engine.attach(self.player)
                    self.attached = true
                    self.engine.connect(self.player, to: self.engine.mainMixerNode, fromBus: 0, toBus: 0, format: self.format)
                    self.engine.connect(self.engine.inputNode, to: self.captureMixer, format: inputFormat)
                    self.captureMixer.outputVolume = 0
                    self.engine.connect(self.captureMixer, to: self.engine.mainMixerNode, fromBus: 0, toBus: 1, format: inputFormat)
                    // Tap input before the muted mixer: playback never contains the local microphone.
                    self.engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] input, _ in
                        guard let self,
                              let copy = AVAudioPCMBuffer(pcmFormat: input.format, frameCapacity: input.frameLength) else { return }
                        copy.frameLength = input.frameLength
                        let source = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input.audioBufferList))
                        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
                        for index in 0..<min(source.count, destination.count) {
                            if let from = source[index].mData, let to = destination[index].mData {
                                memcpy(to, from, Int(min(source[index].mDataByteSize, destination[index].mDataByteSize)))
                            }
                        }
                        self.queue.async { self.capture(copy) }
                    }
                    self.tapped = true
                    self.running = true
                    self.engine.prepare()
                    try self.engine.start()
                    self.player.play()
                    continuation.resume()
                } catch {
                    self.cleanup()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func capture(_ input: AVAudioPCMBuffer) {
        guard running, let converter else { return }
        taps += 1
        let capacity = AVAudioFrameCount(ceil(Double(input.frameLength) * 16000 / input.format.sampleRate)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return }
        var provided = false
        var error: NSError?
        let result = converter.convert(to: output, error: &error) { _, status in
            if provided { status.pointee = .noDataNow; return nil }
            provided = true
            status.pointee = .haveData
            return input
        }
        guard error == nil, result != .error, let values = output.floatChannelData?[0] else {
            conversionErrors += 1
            return
        }
        converted += Int(output.frameLength)
        for index in 0..<Int(output.frameLength) {
            let value = values[index]
            if value.isFinite { capturePeak = max(capturePeak, min(1, abs(value))) }
        }
        guard transmitting else { samples.removeAll(keepingCapacity: true); return }
        samples.append(contentsOf: UnsafeBufferPointer(start: values, count: Int(output.frameLength)))
        while samples.count >= 960 {
            var packet = Data([1])
            packet.reserveCapacity(1921)
            for sample in samples.prefix(960) {
                let value: Float = muted || !sample.isFinite ? 0 : max(-1, min(0.9999695, sample))
                let bits = UInt16(bitPattern: Int16(value * 32768))
                packet.append(UInt8(truncatingIfNeeded: bits))
                packet.append(UInt8(truncatingIfNeeded: bits >> 8))
            }
            samples.removeFirst(960)
            produced += 1
            onFrame?(packet)
        }
    }

    func receive(_ data: Data) {
        queue.async {
            guard self.running, data.count > 1, data.first == 1,
                  (data.count - 1) % 2 == 0, data.count <= 6401,
                  self.playbackPending < 6 else { return }
            self.received += 1
            let bytes = [UInt8](data)
            let count = (bytes.count - 1) / 2
            guard let buffer = AVAudioPCMBuffer(pcmFormat: self.format, frameCapacity: AVAudioFrameCount(count)),
                  let values = buffer.floatChannelData?[0] else { return }
            buffer.frameLength = AVAudioFrameCount(count)
            for index in 0..<count {
                let bits = UInt16(bytes[index * 2 + 1]) | (UInt16(bytes[index * 2 + 2]) << 8)
                values[index] = Float(Int16(bitPattern: bits)) / 32768
                self.receivePeak = max(self.receivePeak, abs(values[index]))
            }
            self.playbackPending += 1
            let generation = self.generation
            self.player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                guard let self else { return }
                self.queue.async {
                    if self.generation == generation {
                        self.playbackPending = max(0, self.playbackPending - 1)
                        self.played += 1
                    }
                }
            }
        }
    }

    func metrics() async -> WhatsAppAudioMetrics {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: WhatsAppAudioMetrics(
                    running: self.running && self.engine.isRunning,
                    transmitting: self.transmitting, muted: self.muted,
                    taps: self.taps, converted: self.converted,
                    conversionErrors: self.conversionErrors, produced: self.produced,
                    received: self.received, played: self.played,
                    capturePeak: self.capturePeak, receivePeak: self.receivePeak,
                    inputRate: self.inputRate
                ))
            }
        }
    }

    func setTransmitting(_ value: Bool) {
        queue.async { self.transmitting = value; self.samples.removeAll(keepingCapacity: true) }
    }
    func setMuted(_ value: Bool) {
        queue.async { self.muted = value; self.samples.removeAll(keepingCapacity: true) }
    }
    func setSpeaker(_ value: Bool, onError: @escaping () -> Void) {
        queue.async {
            do { try AVAudioSession.sharedInstance().overrideOutputAudioPort(value ? .speaker : .none) }
            catch { onError() }
        }
    }
    func stop() { queue.async { self.cleanup() } }
    private func cleanup() {
        running = false; transmitting = false; onFrame = nil
        engine.stop()
        if tapped { engine.inputNode.removeTap(onBus: 0); tapped = false }
        player.stop()
        if attached {
            engine.disconnectNodeOutput(engine.inputNode)
            engine.detach(player)
            engine.detach(captureMixer)
            attached = false
        }
        converter = nil; samples.removeAll(); playbackPending = 0; generation += 1
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
