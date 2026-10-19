import Foundation

@main struct ContactCallDSPRepairTests {
    static func main() {
        let source = (0..<32000).map { Float(sin(Double($0) * 2 * Double.pi * 220 / 16000)) * 0.4 }
        for preset in UltraVoicePreset.allCases {
            let dsp = UltraVoiceDSP(preset: preset)
            let result = source.map { dsp.process($0) }
            precondition(result.allSatisfy { $0.isFinite && abs($0) <= 1 }, "Invalid samples: \(preset)")
            let energy = result.dropFirst(2048).reduce(Float(0)) { $0 + $1 * $1 }
            precondition(energy > 10, "Effect silenced microphone: \(preset)")
            if preset == .natural { precondition(result == source, "Natural effect changed PCM") }
            let wav = UltraVoiceDSP.preview(source, preset: preset)
            precondition(wav.count >= 44 + source.count * 2)
            precondition(String(data: wav.prefix(4), encoding: .utf8) == "RIFF")
            for invalid in [Float.nan, Float.infinity, -Float.infinity] {
                precondition(dsp.process(invalid).isFinite)
            }
            print("PASS voice preset: \(preset.rawValue)")
        }
    }
}
