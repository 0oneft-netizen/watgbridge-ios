import Foundation
import AVFoundation

@main struct ProfessionalUpgradeTests {
    @MainActor static func main() async throws {
        let phones = [
            ("+97255644465", "055644465"), ("+972 54-123-4567", "0541234567"),
            ("00972541234567", "0541234567"), ("+972(0)541234567", "0541234567"),
            ("0541234567", "0541234567"), ("+14155552671", "+14155552671"),
            ("+44 20 1234 5678", "+44 20 1234 5678"), ("972123", "972123"),
            ("+972", "+972"), ("+972bad", "+972bad")
        ]
        for (input, expected) in phones { precondition(IsraeliPhonePresentation.copyValue(input) == expected, input) }
        let c = Conversation(accountID: "a", jid: "972541234567@s.whatsapp.net", name: "Customer", displayPhone: nil, lastMessage: "", lastMessageAt: 0, unread: 0, pinned: nil, archived: nil, muted: nil)
        precondition(ChatIdentity.customerPhone(conversation: c) == "+972541234567", "Routing number must stay canonical")
        precondition(ChatIdentity.copyPhone(conversation: c) == "0541234567")
        let unresolved = Conversation(accountID: "a", jid: "123456789@lid", name: "", displayPhone: nil, lastMessage: "", lastMessageAt: 0, unread: 0, pinned: nil, archived: nil, muted: nil)
        precondition(ChatIdentity.copyPhone(conversation: unresolved).isEmpty, "Never copy an unresolved LID as a phone")
        print("PASS: phone presentation, foreign preservation, canonical routing and LID safety")

        let scopeA = "professional-a-" + UUID().uuidString
        let scopeB = "professional-b-" + UUID().uuidString
        defer { UserDefaults.standard.removePersistentDomain(forName: "watgbridge.user." + scopeA); UserDefaults.standard.removePersistentDomain(forName: "watgbridge.user." + scopeB); UserWorkspace.select(nil) }
        UserWorkspace.select(scopeA)
        let drafts = ChatDraftStore.shared
        drafts.save("First draft", accountID: "a", chatJID: "same")
        drafts.save("Second draft", accountID: "b", chatJID: "same")
        precondition(drafts.text(accountID: "a", chatJID: "same") == "First draft")
        precondition(drafts.text(accountID: "b", chatJID: "same") == "Second draft")
        UserWorkspace.select(scopeB)
        precondition(drafts.text(accountID: "a", chatJID: "same").isEmpty)
        UserWorkspace.select(scopeA); drafts.clear(accountID: "a", chatJID: "same")
        precondition(drafts.text(accountID: "a", chatJID: "same").isEmpty)
        precondition(drafts.text(accountID: "b", chatJID: "same") == "Second draft")
        precondition(BusinessChatFilter.drafts.includes(c, hasDraft: true))
        precondition(!BusinessChatFilter.drafts.includes(c, hasDraft: false))
        precondition(BusinessChatFilter.attention.includes(c, needsAttention: true))
        precondition(!BusinessChatFilter.attention.includes(c, needsAttention: false))
        print("PASS: draft/account/workspace isolation and new inbox filters")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("original.caf")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        do {
            let file = try AVAudioFile(forWriting: input, settings: format.settings)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100)!
            buffer.frameLength = 44100
            for channel in 0..<2 {
                for frame in 0..<44100 { buffer.floatChannelData![channel][frame] = Float(0.3 * sin(2 * Double.pi * 440 * Double(frame) / 44100)) }
            }
            try file.write(from: buffer)
        }
        for preset in UltraVoicePreset.allCases {
            let rendered = try await VoiceNoteEffectProcessor.prepare(input: input, preset: preset)
            defer { if rendered != input { try? FileManager.default.removeItem(at: rendered) } }
            if preset == .natural { precondition(rendered == input); continue }
            precondition(rendered != input)
            let file = try AVAudioFile(forReading: rendered)
            let duration = Double(file.length) / file.processingFormat.sampleRate
            precondition(abs(duration - 1) < 0.12, "Duration drift: \(preset) \(duration)")
            precondition(file.processingFormat.sampleRate == 16000 && file.processingFormat.channelCount == 1)
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: buffer)
            let values = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
            precondition(values.allSatisfy { $0.isFinite && abs($0) <= 1 })
            precondition(values.contains { abs($0) > 0.02 }, "Silent effect: \(preset)")
            if preset.ratio != 1 {
                let segment = Array(values[4000..<12000])
                func energy(_ frequency: Double) -> Double {
                    let coefficient = 2 * cos(2 * Double.pi * frequency / 16000)
                    var previous = 0.0, older = 0.0
                    for sample in segment { let current = Double(sample) + coefficient * previous - older; older = previous; previous = current }
                    return previous * previous + older * older - coefficient * previous * older
                }
                let strongest = stride(from: 250.0, through: 650.0, by: 2).max { energy($0) < energy($1) }!
                precondition(abs(strongest - 440 * preset.ratio) < 25, "Wrong note pitch: \(preset) \(strongest)")
            }
            print("PASS: actual voice-note conversion, PCM, duration and effect:", preset.rawValue)
        }
        let malformed = directory.appendingPathComponent("bad.m4a")
        try Data("not audio".utf8).write(to: malformed)
        do { _ = try await VoiceNoteEffectProcessor.prepare(input: malformed, preset: .deep); preconditionFailure("Invalid input must not fall back to natural") } catch {}
        print("PASS: invalid note fails closed; no unprocessed fallback")
    }
}
