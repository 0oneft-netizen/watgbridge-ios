import AVFoundation
import Foundation

enum UltraVoiceSettings {
    static let key = "ultra.voice.preset.v1"
    static var selected: UltraVoicePreset {
        get { UltraVoicePreset(rawValue: UserWorkspace.defaults.string(forKey: key) ?? "") ?? .natural }
        set { UserWorkspace.defaults.set(newValue.rawValue, forKey: key) }
    }
}

/// Prevent a preview from reconfiguring AVAudioSession during an actual call.
enum UltraAudioLease {
    private static let lock = NSLock()
    private static var owner: UUID?
    static func acquire(_ id: UUID) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard owner == nil || owner == id else { return false }
        owner = id; return true
    }
    static func release(_ id: UUID) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard owner == id else { return false }
        owner = nil; return true
    }
}

enum UltraVoiceError: LocalizedError {
    case busy
    var errorDescription: String? { "השמע נמצא בשימוש. סיים את השיחה או את התצוגה המקדימה ונסה שוב." }
}

@MainActor
final class UltraVoicePreview: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var recording = false
    @Published private(set) var playing = false
    @Published private(set) var preparing = false
    @Published private(set) var hasSample = false
    @Published private(set) var error: String?
    private var original: [Float] = []
    private var audio: WhatsAppCallAudio?
    private var player: AVAudioPlayer?
    private var task: Task<Void, Never>?
    private var token = UUID()
    private let playbackLease = UUID()
    private var ownsPlayback = false
    private let scope = UserWorkspace.id
    private var accessObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?

    override init() {
        super.init()
        accessObserver = NotificationCenter.default.addObserver(forName: .userAccessEnded, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stop(clear: true) }
        }
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stop(clear: false) }
        }
    }

    func record() {
        guard !recording, !preparing, scope == UserWorkspace.id else { return }
        stop(clear: true); error = nil; preparing = true
        let id = token
        task = Task {
            let allowed = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
            guard id == token, !Task.isCancelled, scope == UserWorkspace.id else { return }
            guard allowed else { preparing = false; error = "יש לאפשר גישה למיקרופון בהגדרות האייפון."; return }
            let capture = WhatsAppCallAudio()
            audio = capture
            do {
                try await capture.start(speaker: true, effect: .natural, onFailure: { [weak self] in
                    Task { @MainActor in self?.fail("ההקלטה הופסקה. נסה שוב.") }
                }) { [weak self] packet in
                    Task { @MainActor in self?.append(packet, id: id) }
                }
                guard id == token, !Task.isCancelled, scope == UserWorkspace.id else { await capture.stopAndWait(); return }
                preparing = false; recording = true
                capture.setTransmitting(true)
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await capture.stopAndWait()
                guard id == token, !Task.isCancelled, scope == UserWorkspace.id else { return }
                audio = nil; recording = false; hasSample = !original.isEmpty
                if !hasSample { error = "לא התקבל שמע מהמיקרופון. נסה שוב." }
            } catch {
                await capture.stopAndWait()
                guard id == token, !Task.isCancelled else { return }
                audio = nil; preparing = false; recording = false
                self.error = error.localizedDescription
            }
        }
    }

    private func append(_ data: Data, id: UUID) {
        guard id == token, recording, original.count < 48000, data.first == 1 else { return }
        let bytes = [UInt8](data)
        guard bytes.count > 1, (bytes.count - 1) % 2 == 0 else { return }
        for i in stride(from: 1, to: bytes.count - 1, by: 2) {
            guard original.count < 48000 else { break }
            let bits = UInt16(bytes[i]) | UInt16(bytes[i + 1]) << 8
            original.append(Float(Int16(bitPattern: bits)) / 32768)
        }
    }

    func play(_ preset: UltraVoicePreset) {
        guard hasSample, !recording, !preparing, scope == UserWorkspace.id else { return }
        stopPlayback(); error = nil
        guard UltraAudioLease.acquire(playbackLease) else { error = UltraVoiceError.busy.localizedDescription; return }
        ownsPlayback = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let sound = try AVAudioPlayer(data: UltraVoiceDSP.preview(original, preset: preset))
            sound.delegate = self; sound.prepareToPlay(); player = sound
            guard sound.play() else { throw URLError(.cannotDecodeContentData) }
            playing = true
        } catch { stopPlayback(); self.error = error.localizedDescription }
    }

    private func fail(_ message: String) { stop(clear: false); error = message }
    func stop(clear: Bool) {
        token = UUID(); task?.cancel(); task = nil
        audio?.stop(); audio = nil
        recording = false; preparing = false; stopPlayback()
        if clear { original.removeAll(); hasSample = false }
    }
    private func stopPlayback() {
        player?.stop(); player = nil; playing = false
        if ownsPlayback {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            _ = UltraAudioLease.release(playbackLease); ownsPlayback = false
        }
    }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard self?.player === player else { return }
            self?.stopPlayback()
        }
    }
    deinit {
        if let accessObserver { NotificationCenter.default.removeObserver(accessObserver) }
        if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
    }
}
