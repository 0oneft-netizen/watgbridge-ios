import Foundation

@main struct UltraVoiceContracts {
    static func main() {
        let tone = (0..<32000).map { Float(0.35 * sin(2 * Double.pi * 440 * Double($0) / 16000)) }
        let natural = UltraVoiceDSP(preset: .natural)
        precondition(tone.map(natural.process) == tone, "Natural must preserve ordinary PCM")
        for preset in UltraVoicePreset.allCases {
            let dsp = UltraVoiceDSP(preset: preset)
            let rendered = tone.map(dsp.process)
            precondition(rendered.count == tone.count)
            precondition(rendered.allSatisfy { $0.isFinite && abs($0) <= 1 })
            precondition(rendered.dropFirst(1000).contains { abs($0) > 0.01 })
            // The waveform's strongest spectral line must track the selected ratio.
            if preset.ratio != 1 {
                let segment = Array(rendered[16000..<24000])
                func energy(_ frequency: Double) -> Double {
                    let omega = 2 * Double.pi * frequency / 16000
                    let coefficient = 2 * cos(omega)
                    var previous = 0.0, older = 0.0
                    for value in segment {
                        let current = Double(value) + coefficient * previous - older
                        older = previous; previous = current
                    }
                    return previous * previous + older * older - coefficient * previous * older
                }
                let strongest = stride(from: 250.0, through: 650.0, by: 2).max { energy($0) < energy($1) }!
                precondition(abs(strongest - 440 * preset.ratio) < 20, "Pitch mismatch: \(preset) \(strongest)")
            }
            let wav = UltraVoiceDSP.preview(tone, preset: preset)
            precondition(String(data: wav.prefix(4), encoding: .utf8) == "RIFF")
            precondition(String(data: wav[8..<12], encoding: .utf8) == "WAVE")
            let count = tone.count + (preset.ratio == 1 ? 0 : 704)
            precondition(wav.count == 44 + count * 2)
            let dirty = UltraVoiceDSP(preset: preset)
            for value in [Float.nan, Float.infinity, -Float.infinity, Float(200), Float(-200)] {
                let output = dirty.process(value)
                precondition(output.isFinite && abs(output) <= 1)
            }
        }
        // A network packet boundary must never reset the pitch delay or phase.
        let a = UltraVoiceDSP(preset: .deep), b = UltraVoiceDSP(preset: .deep)
        let whole = tone.map(a.process)
        var chunked: [Float] = []
        for start in stride(from: 0, to: tone.count, by: 960) {
            chunked.append(contentsOf: tone[start..<min(start + 960, tone.count)].map(b.process))
        }
        precondition(whole == chunked)
        print("PASS: six effects, unchanged natural audio, pitch spectrum, finite/clipped samples, streaming continuity, WAV preview")
    }
}
