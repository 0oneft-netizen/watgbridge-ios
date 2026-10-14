import Foundation

enum UltraVoicePreset: String, CaseIterable, Identifiable {
    case natural, warm, deep, bright, high, robot
    var id: String { rawValue }
    var title: String {
        switch self {
        case .natural: return "טבעי"
        case .warm: return "נמוך וחם"
        case .deep: return "עמוק"
        case .bright: return "בהיר"
        case .high: return "גבוה"
        case .robot: return "רובוטי"
        }
    }
    var subtitle: String {
        switch self {
        case .natural: return "הקול שלך ללא אפקט"
        case .warm: return "הנמכה עדינה לשיחה ברורה"
        case .deep: return "גובה צליל נמוך ומודגש"
        case .bright: return "גובה צליל מוגבה בעדינות"
        case .high: return "גובה צליל גבוה ומורגש"
        case .robot: return "אפקט אלקטרוני עם הדיבור המקורי"
        }
    }
    var ratio: Double {
        switch self {
        case .natural, .robot: return 1
        case .warm: return 0.90
        case .deep: return 0.78
        case .bright: return 1.14
        case .high: return 1.28
        }
    }
}

/// Streaming, fixed-memory pitch effect at the call wire format: 16 kHz mono.
/// Two interpolated delay heads crossfade at their wraps. Input/output duration
/// stays equal; no growing queue, file, network request or additional audio graph.
/// This is a creative effect, not voice cloning or a guarantee of anonymity.
final class UltraVoiceDSP {
    let preset: UltraVoicePreset
    private var ring = [Float](repeating: 0, count: 2048)
    private var write = 0
    private var phase: Double = 0
    private var carrier: Double = 0
    private let window: Double = 640
    init(preset: UltraVoicePreset) { self.preset = preset }

    private func delayed(_ distance: Double) -> Float {
        let position = Double(write) - distance
        let base = Int(floor(position))
        let fraction = Float(position - floor(position))
        let first = ring[base & 2047]
        return first + (ring[(base + 1) & 2047] - first) * fraction
    }

    func process(_ input: Float) -> Float {
        let clean: Float = input.isFinite ? max(-1, min(1, input)) : 0
        if preset == .natural { return clean }
        var output = clean
        if preset.ratio != 1 {
            ring[write] = clean
            let other = (phase + 0.5).truncatingRemainder(dividingBy: 1)
            let weight = Float(1 - abs(phase * 2 - 1))
            output = delayed(32 + phase * window) * weight
                + delayed(32 + other * window) * (1 - weight)
            write = (write + 1) & 2047
            phase += (1 - preset.ratio) / window
            phase -= floor(phase)
        }
        if preset == .robot {
            output *= Float(0.4 + 0.6 * sin(carrier))
            carrier += 2 * Double.pi * 65 / 16000
            if carrier >= 2 * Double.pi { carrier -= 2 * Double.pi }
        }
        return max(-1, min(1, output))
    }

    static func preview(_ input: [Float], preset: UltraVoicePreset) -> Data {
        let dsp = UltraVoiceDSP(preset: preset)
        // Preserve the final syllable through the bounded delay during preview.
        let padding = preset.ratio == 1 ? 0 : 704
        var pcm = Data(capacity: (input.count + padding) * 2)
        for index in 0..<(input.count + padding) {
            let value = max(-1, min(0.9999695, dsp.process(index < input.count ? input[index] : 0)))
            let bits = UInt16(bitPattern: Int16(value * 32768))
            pcm.append(UInt8(truncatingIfNeeded: bits))
            pcm.append(UInt8(truncatingIfNeeded: bits >> 8))
        }
        var wav = Data("RIFF".utf8)
        func u32(_ v: UInt32) { var n = v.littleEndian; withUnsafeBytes(of: &n) { wav.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { var n = v.littleEndian; withUnsafeBytes(of: &n) { wav.append(contentsOf: $0) } }
        u32(UInt32(36 + pcm.count)); wav.append(Data("WAVEfmt ".utf8)); u32(16)
        u16(1); u16(1); u32(16000); u32(32000); u16(2); u16(16)
        wav.append(Data("data".utf8)); u32(UInt32(pcm.count)); wav.append(pcm)
        return wav
    }
}
