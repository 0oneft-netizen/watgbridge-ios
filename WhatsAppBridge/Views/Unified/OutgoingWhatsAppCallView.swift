import SwiftUI
import UIKit

@MainActor
struct OutgoingWhatsAppCallView: View {
    let destination: WhatsAppCallDestination
    @StateObject private var call = WhatsAppCallSession()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text(destination.name).font(.title2.weight(.semibold))
                    Text(SessionDirectory.shared.name(for: destination.accountID))
                        .font(.caption).foregroundStyle(.white.opacity(0.7))
                    Text(call.statusText).font(.subheadline)
                    if let connected = call.connectedAt, !call.finished {
                        TimelineView(.periodic(from: connected, by: 1)) { timeline in
                            let seconds = max(0, Int(timeline.date.timeIntervalSince(connected)))
                            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                                .monospacedDigit().font(.caption)
                        }
                    }
                }
                if destination.video {
                    ZStack {
                        CallReceivedVideoView(renderer: call.video)
                        if !call.receivedVideo {
                            VStack(spacing: 12) {
                                Image(systemName: "video").font(.largeTitle)
                                Text(call.finished ? "השיחה הסתיימה" : "ממתין לווידאו מהלקוח")
                                    .font(.subheadline)
                            }.foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    Label("המצלמה שלך חסומה · מתקבל וידאו מהלקוח בלבד", systemImage: "video.slash.fill")
                        .font(.caption).multilineTextAlignment(.center)
                } else {
                    Spacer()
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 100)).foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
                if let error = call.errorText {
                    Text(error).font(.subheadline).multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                }
                if call.finished {
                    Button("סגירה") { dismiss() }
                        .font(.headline).padding().frame(maxWidth: .infinity)
                        .background(ChatDesign.accent).clipShape(Capsule())
                } else {
                    HStack(spacing: 32) {
                        control(call.muted ? "mic.slash.fill" : "mic.fill", title: "השתקה", selected: call.muted) { call.toggleMuted() }
                        control("speaker.wave.2.fill", title: "רמקול", selected: call.speaker) { call.toggleSpeaker() }
                        VStack(spacing: 8) {
                            Button { call.hangup() } label: {
                                Image(systemName: "phone.down.fill").font(.title2)
                                    .frame(width: 62, height: 62).background(Color.red).clipShape(Circle())
                            }.accessibilityLabel("ניתוק שיחה")
                            Text("ניתוק").font(.caption)
                        }
                    }
                }
            }
            .padding(24)
        }
        .foregroundStyle(.white)
        .interactiveDismissDisabled(!call.finished)
        .task { call.start(destination) }
        .onDisappear { call.hangup() }
    }
    private func control(_ icon: String, title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon).font(.title2)
                    .foregroundStyle(selected ? Color.black : Color.white)
                    .frame(width: 62, height: 62)
                    .background(selected ? Color.white : Color.white.opacity(0.18)).clipShape(Circle())
            }.accessibilityLabel(title).accessibilityValue(selected ? "פעיל" : "כבוי")
            Text(title).font(.caption)
        }
    }
}

@MainActor
private struct CallReceivedVideoView: UIViewRepresentable {
    let renderer: WhatsAppReceiveVideo
    func makeUIView(context: Context) -> ReceivedVideoSurface { ReceivedVideoSurface(renderer: renderer) }
    func updateUIView(_ uiView: ReceivedVideoSurface, context: Context) {}
}
private final class ReceivedVideoSurface: UIView {
    let renderer: WhatsAppReceiveVideo
    init(renderer: WhatsAppReceiveVideo) {
        self.renderer = renderer
        super.init(frame: .zero)
        backgroundColor = .black
        layer.addSublayer(renderer.layer)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() { super.layoutSubviews(); renderer.layer.frame = bounds }
}
