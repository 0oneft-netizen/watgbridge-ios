import Foundation
import AVFoundation

// Bounded streaming conversion. Uses exactly the 16 kHz DSP used by call previews.
// Only the rendered file is exposed to the review/send UI; failures never fall back
// to sending an unprocessed recording when an effect was selected.
enum VoiceNoteEffectProcessor {
    enum ProcessingError: LocalizedError {
        case invalidAudio, conversionFailed
        var errorDescription: String? { "לא ניתן להכין את ההקלטה עם האפקט. הקול המקורי לא נשלח." }
    }
    static func render(input: URL, preset: UltraVoicePreset) throws -> URL {
        try Task.checkCancellation()
        if preset == .natural { return input }
        let source = try AVAudioFile(forReading: input, commonFormat: .pcmFormatFloat32, interleaved: false)
        let inputFormat = source.processingFormat
        guard source.length > 0, inputFormat.sampleRate > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let converter = AVAudioConverter(from: inputFormat, to: format) else { throw ProcessingError.invalidAudio }
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("voice-effect-\(UUID().uuidString).caf")
        var completed = false
        defer { if !completed { try? FileManager.default.removeItem(at: target) } }
        let output = try AVAudioFile(forWriting: target, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        let dsp = UltraVoiceDSP(preset: preset)
        var reachedEnd = false
        var inputError: Error?
        var written: AVAudioFramePosition = 0
        while true {
            try Task.checkCancellation()
            guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096) else { throw ProcessingError.conversionFailed }
            var conversionError: NSError?
            let status = converter.convert(to: converted, error: &conversionError) { requested, state in
                if reachedEnd { state.pointee = .endOfStream; return nil }
                let frames = max(1, min(4096, Int(requested)))
                guard let buffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(frames)) else {
                    inputError = ProcessingError.conversionFailed; reachedEnd = true; state.pointee = .endOfStream; return nil
                }
                do { try source.read(into: buffer, frameCount: AVAudioFrameCount(frames)) }
                catch { inputError = error; reachedEnd = true; state.pointee = .endOfStream; return nil }
                guard buffer.frameLength > 0 else { reachedEnd = true; state.pointee = .endOfStream; return nil }
                state.pointee = .haveData
                return buffer
            }
            if let inputError { throw inputError }
            if let conversionError { throw conversionError }
            guard status != .error else { throw ProcessingError.conversionFailed }
            if let samples = converted.floatChannelData?[0], converted.frameLength > 0 {
                for index in 0..<Int(converted.frameLength) { samples[index] = dsp.process(samples[index]) }
                try output.write(from: converted); written += AVAudioFramePosition(converted.frameLength)
            }
            if status == .endOfStream { break }
            if status == .inputRanDry && reachedEnd { break }
        }
        guard written > 0 else { throw ProcessingError.invalidAudio }
        if preset.ratio != 1 {
            guard let tail = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 704), let values = tail.floatChannelData?[0] else { throw ProcessingError.conversionFailed }
            tail.frameLength = 704
            for index in 0..<704 { values[index] = dsp.process(0) }
            try output.write(from: tail)
        }
        try Task.checkCancellation()
        completed = true
        return target
    }
    static func prepare(input: URL, preset: UltraVoicePreset) async throws -> URL {
        let task = Task.detached(priority: .userInitiated) { try render(input: input, preset: preset) }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }
}
