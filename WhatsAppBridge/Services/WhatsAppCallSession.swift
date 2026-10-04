import AVFoundation
import Foundation
import UIKit

struct WhatsAppCallDestination: Identifiable {
    let id = UUID()
    let accountID: String
    let chatJID: String
    let name: String
    let video: Bool
}

@MainActor
final class WhatsAppCallSession: ObservableObject {
    @Published private(set) var state = "preparing"
    @Published private(set) var errorText: String?
    @Published private(set) var finished = false
    @Published private(set) var muted = false
    @Published private(set) var speaker = false
    @Published private(set) var connectedAt: Date?
    @Published private(set) var receivedVideo = false
    let video = WhatsAppReceiveVideo()
    private let audio = WhatsAppCallAudio()
    private var socket: URLSessionWebSocketTask?
    private var networkSession: URLSession?
    private var startup: Task<Void, Never>?
    private var receiver: Task<Void, Never>?
    private var heartbeat: Task<Void, Never>?
    private var sending: Task<Void, Never>?
    private var observer: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private var accessObserver: NSObjectProtocol?
    private var outbox: [URLSessionWebSocketTask.Message] = []
    private var lastReceived = Date()
    private var began = false
    private var wantsVideo = false

    var statusText: String {
        switch state {
        case "preparing": return "מכין את המיקרופון…"
        case "calling": return "מחייג…"
        case "ringing": return "מצלצל אצל הלקוח…"
        case "connecting": return "הלקוח ענה, מחבר קול…"
        case "active": return "השיחה מחוברת"
        case "ended": return "השיחה הסתיימה"
        default: return "לא ניתן לחבר את השיחה"
        }
    }

    func start(_ destination: WhatsAppCallDestination) {
        guard !began else { return }; began = true
        wantsVideo = destination.video; speaker = destination.video
        accessObserver = NotificationCenter.default.addObserver(forName: .userAccessEnded, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.end(message: "החשבון התנתק.") } }
        observer = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if type == AVAudioSession.InterruptionType.began.rawValue {
                Task { @MainActor in self?.end(message: "השיחה הופסקה בגלל שינוי במצב השמע באייפון.") }
            }
        }
        routeObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue || reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue {
                Task { @MainActor in self?.end(message: "התקן השמע השתנה. אפשר לחייג שוב עם ההתקן החדש.") }
            }
        }
        startup = Task {
            let permitted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
            guard !Task.isCancelled, !finished else { return }
            guard permitted else { end(message: "צריך לאפשר גישה למיקרופון בהגדרות האייפון כדי לבצע שיחה."); return }
            do {
                try await audio.start(speaker: speaker) { [weak self] packet in
                    Task { @MainActor in self?.sendMicrophone(packet) }
                }
                guard !finished, !Task.isCancelled else { audio.stop(); return }
                var url = URLComponents(url: APIClient.shared.baseURL.appendingPathComponent("calls/socket"), resolvingAgainstBaseURL: false)!
                guard url.scheme == "https" else { throw URLError(.secureConnectionFailed) }
                url.scheme = "wss"
                url.queryItems = [URLQueryItem(name: "account_id", value: destination.accountID), URLQueryItem(name: "chat_jid", value: destination.chatJID)]
                guard let endpoint = url.url else { throw URLError(.badURL) }
                let configuration = URLSessionConfiguration.ephemeral
                configuration.httpCookieStorage = .shared
                configuration.timeoutIntervalForRequest = 20
                configuration.timeoutIntervalForResource = 14400
                let network = URLSession(configuration: configuration)
                networkSession = network
                let task = network.webSocketTask(with: endpoint)
                task.maximumMessageSize = 1024 * 1024 + 1
                socket = task; task.resume()
                state = "calling"; lastReceived = Date()
                enqueueControl(["type": "start", "video": destination.video])
                receiver = Task { [weak self] in
                    do {
                        while !Task.isCancelled {
                            let message = try await task.receive()
                            guard let self, !self.finished else { return }
                            self.lastReceived = Date()
                            switch message {
                            case .data(let packet):
                                if packet.first == 1 { self.audio.receive(packet) }
                                else if packet.first == 2, self.wantsVideo {
                                    if self.video.receive(Data(packet.dropFirst())) { self.receivedVideo = true }
                                }
                            case .string(let text): self.receiveState(text)
                            @unknown default: break
                            }
                        }
                    } catch {
                        guard let self, !self.finished else { return }
                        let status = (task.response as? HTTPURLResponse)?.statusCode
                        let text = status == 409 ? "הסשן אינו מחובר או שכבר מתבצעת בו שיחה." : "החיבור לשיחה נותק. בדוק שהסשן והחיבור לשרת פעילים."
                        self.end(message: text)
                    }
                }
                heartbeat = Task { [weak self] in
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        guard !Task.isCancelled, let self, !self.finished else { return }
                        if Date().timeIntervalSince(self.lastReceived) > 35 { self.end(message: "לא התקבלה תשובה מהשרת. השיחה נסגרה."); return }
                        self.enqueueControl(["type": "ping"])
                    }
                }
            } catch { end(message: "לא ניתן לפתוח את המיקרופון או להתחבר לשירות השיחות.") }
        }
    }

    private func receiveState(_ text: String) {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["camera_locked"] as? Bool == true,
              let next = object["state"] as? String else {
            end(message: "השרת אינו תואם למדיניות חסימת המצלמה."); return
        }
        if next == "heartbeat" { return }
        if next == "ended" || next == "error" {
            let reason = (object["reason"] as? String) ?? ""
            let text: String?
            switch reason {
            case "dial_failed": text = "WhatsApp לא אישר את החיוג. בדוק שהסשן מחובר ושהלקוח זמין."
            case "answer_timeout": text = "הלקוח לא ענה בזמן או שחיבור המדיה לא הושלם."
            case "duration_limit": text = "השיחה הגיעה למגבלת הזמן."
            default: text = nil
            }
            end(message: text); return
        }
        guard ["calling", "ringing", "connecting", "active"].contains(next) else { return }
        // Late signaling must not make a connected call appear to be ringing again.
        if connectedAt != nil && next != "active" { return }
        state = next
        if next == "active", connectedAt == nil { connectedAt = Date(); audio.setTransmitting(true) }
    }
    private func sendMicrophone(_ packet: Data) {
        guard state == "active", !finished else { return }
        // Keep at most four frames (240 ms). Never grow an unbounded send backlog.
        let audioCount = outbox.reduce(0) { count, message in
            if case .data = message { return count + 1 }; return count
        }
        if audioCount >= 4 {
            if let index = outbox.firstIndex(where: { if case .data = $0 { return true }; return false }) { outbox.remove(at: index) }
        }
        outbox.append(.data(packet)); pump()
    }
    private func enqueueControl(_ object: [String: Any]) {
        guard !finished, let data = try? JSONSerialization.data(withJSONObject: object),
              let text = String(data: data, encoding: .utf8) else { return }
        outbox.append(.string(text)); pump()
    }
    private func pump() {
        guard sending == nil, let socket, !outbox.isEmpty, !finished else { return }
        sending = Task { [weak self] in
            guard let self else { return }
            do {
                while !self.outbox.isEmpty, !self.finished, !Task.isCancelled {
                    let next = self.outbox.removeFirst()
                    try await socket.send(next)
                }
            } catch { if !self.finished { self.end(message: "שליחת הקול הופסקה בגלל ניתוק בחיבור.") } }
            self.sending = nil
            if !self.finished { self.pump() }
        }
    }
    func toggleMuted() {
        guard !finished else { return }; muted.toggle()
        outbox.removeAll { if case .data = $0 { return true }; return false }
        audio.setMuted(muted); enqueueControl(["type": "mute", "muted": muted])
    }
    func toggleSpeaker() {
        guard !finished else { return }; speaker.toggle()
        audio.setSpeaker(speaker) { [weak self] in
            Task { @MainActor in self?.end(message: "לא ניתן להחליף את יציאת השמע.") }
        }
    }
    func hangup() { end(message: nil) }
    private func end(message: String?) {
        guard !finished else { return }
        finished = true; state = "ended"; errorText = message
        startup?.cancel(); receiver?.cancel(); heartbeat?.cancel(); sending?.cancel()
        outbox.removeAll(); audio.stop(); video.stop()
        // Closing the owning websocket always hangs up on the server, including errors.
        socket?.cancel(with: .normalClosure, reason: nil); socket = nil
        networkSession?.invalidateAndCancel(); networkSession = nil
        if let observer { NotificationCenter.default.removeObserver(observer); self.observer = nil }
        if let routeObserver { NotificationCenter.default.removeObserver(routeObserver); self.routeObserver = nil }
        if let accessObserver { NotificationCenter.default.removeObserver(accessObserver); self.accessObserver = nil }
    }
}
