import Foundation
import AVFoundation

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private let audioLease = UUID()
    private var ownsAudio = false
    private var starting = false
    private var generation = 0

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-\(UUID().uuidString).m4a")
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission {
                continuation.resume(returning: $0)
            }
        }
    }

    func start() async throws {
        guard !isRecording, !starting else { return }
        starting = true; let token = generation; let scope = UserWorkspace.id
        defer { starting = false }
        guard await requestPermission() else {
            throw RecorderError.permissionDenied
        }
        guard generation == token, UserWorkspace.id == scope else { throw CancellationError() }
        guard UltraAudioLease.acquire(audioLease) else { throw UltraVoiceError.busy }
        ownsAudio = true
        var startedURL: URL?
        do {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [
                .defaultToSpeaker,
                .allowBluetooth
            ]
        )

        try session.setActive(true)

        let url = recordingURL
        startedURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey:
                AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(
            url: url,
            settings: settings
        )

        recorder?.prepareToRecord()
        guard recorder?.record() == true else { throw URLError(.cannotCreateFile) }

        elapsed = 0
        isRecording = true

        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.elapsed =
                    self?.recorder?.currentTime ?? 0
            }
        }
        } catch {
            recorder?.stop(); recorder = nil
            if let startedURL { try? FileManager.default.removeItem(at: startedURL) }
            if ownsAudio { _ = UltraAudioLease.release(audioLease); ownsAudio = false; try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
            throw error
        }
    }

    func stop() -> URL? {
        guard let recorder else {
            return nil
        }

        recorder.stop()

        timer?.invalidate()
        timer = nil

        isRecording = false

        let url = recorder.url

        self.recorder = nil

        if ownsAudio {
            _ = UltraAudioLease.release(audioLease); ownsAudio = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }

        return url
    }

    func cancel() {
        generation += 1
        let url = stop()

        if let url {
            try? FileManager.default
                .removeItem(at: url)
        }
    }
}

enum RecorderError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission was denied."
        }
    }
}
