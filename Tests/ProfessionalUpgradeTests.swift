import Foundation
import AVFoundation
import Darwin

@main struct ProfessionalUpgradeTests {
    @MainActor static func main() async {
        setbuf(stdout, nil)
        do { try await run() }
        catch {
            let error = error as NSError
            fputs("FAIL: professional audio test: \(error.domain) code=\(error.code) \(error.userInfo)\n", stderr)
            exit(1)
        }
    }
    @MainActor static func run() async throws {
        let avatarA = AvatarRequest(accountID: "session-a", jid: "123@s.whatsapp.net")
        let avatarB = AvatarRequest(accountID: "session-b", jid: "123@s.whatsapp.net")
        precondition(avatarA.queryItems.contains { $0.name == "account_id" && $0.value == "session-a" })
        precondition(avatarB.queryItems.contains { $0.name == "account_id" && $0.value == "session-b" })
        precondition(AvatarIdentity(accountID: "session-a", jid: avatarA.jid).cacheKey != AvatarIdentity(accountID: "session-b", jid: avatarA.jid).cacheKey)
        print("PASS: avatar requests preserve the selected account")
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
            print("CHECK: create 44.1 kHz stereo PCM16 fixture")
            let fileSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100.0, AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false
            ]
            var file: AVAudioFile? = try AVAudioFile(forWriting: input, settings: fileSettings, commonFormat: .pcmFormatFloat32, interleaved: false)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100)!
            buffer.frameLength = 44100
            for channel in 0..<2 {
                for frame in 0..<44100 { buffer.floatChannelData![channel][frame] = Float(0.3 * sin(2 * Double.pi * 440 * Double(frame) / 44100)) }
            }
            try file!.write(from: buffer)
            file = nil // Finish the fixture before any preset opens it.
        }
        for preset in UltraVoicePreset.allCases {
            print("CHECK: render voice-note preset", preset.rawValue)
            let rendered = try await VoiceNoteEffectProcessor.prepare(input: input, preset: preset)
            defer { if rendered != input { try? FileManager.default.removeItem(at: rendered) } }
            // Exercise the actual review/send format, including an effected CAF
            // exported to the M4A uploaded by ChatView.sendVoice.
            let upload = directory.appendingPathComponent("upload-\(preset.rawValue).m4a")
            guard let export = AVAssetExportSession(asset: AVURLAsset(url: rendered), presetName: AVAssetExportPresetAppleM4A) else { fatalError("Cannot create voice upload exporter") }
            export.outputURL = upload; export.outputFileType = .m4a
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in export.exportAsynchronously { continuation.resume() } }
            guard export.status == .completed else { throw export.error ?? NSError(domain: "VoiceUploadExport", code: 1) }
            let uploadFile = try AVAudioFile(forReading: upload)
            precondition(uploadFile.length > 0, "Empty voice upload")
            let uploadBuffer = AVAudioPCMBuffer(pcmFormat: uploadFile.processingFormat, frameCapacity: 1024)!
            try uploadFile.read(into: uploadBuffer, frameCount: min(1024, AVAudioFrameCount(uploadFile.length)))
            precondition(uploadBuffer.frameLength > 0)
            print("PASS: playable M4A voice upload", preset.rawValue)
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
        for frames in [1, 4096, 4097] {
            print("CHECK: EOF boundary", frames)
            let boundary = directory.appendingPathComponent("boundary-\(frames).caf")
            let mono = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000.0, AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false]
            var writer: AVAudioFile? = try AVAudioFile(forWriting: boundary, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            let buffer = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: AVAudioFrameCount(frames))!
            buffer.frameLength = AVAudioFrameCount(frames)
            for index in 0..<frames { buffer.floatChannelData![0][index] = 0.2 }
            try writer!.write(from: buffer); writer = nil
            let processed = try await VoiceNoteEffectProcessor.prepare(input: boundary, preset: .warm)
            defer { try? FileManager.default.removeItem(at: processed) }
            let decoded = try AVAudioFile(forReading: processed)
            precondition(decoded.length >= AVAudioFramePosition(frames) && decoded.length <= AVAudioFramePosition(frames + 1000), "EOF lost or duplicated samples")
        }
        print("PASS: short, exact-block and partial-block EOF inputs")
        let malformed = directory.appendingPathComponent("bad.m4a")
        try Data("not audio".utf8).write(to: malformed)
        do { _ = try await VoiceNoteEffectProcessor.prepare(input: malformed, preset: .deep); preconditionFailure("Invalid input must not fall back to natural") } catch {}
        print("PASS: invalid note fails closed; no unprocessed fallback")
    }
}
