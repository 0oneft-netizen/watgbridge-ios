import SwiftUI
import UIKit

struct UnifiedMessageBubble: View {
    @ObservedObject private var ultraStore = UltraChatStore.shared
    @State private var ultraForward = false
    @State private var showReceiptInfo = false
    @State private var showVoiceTranscript = false
    @State private var ultraTranslationError: String?
    let message: Message
    let senderName: String
    let accountName: String?
    let quotedText: String?

    let onReply: () -> Void
    let onReact: (String) -> Void
    let onDeleteLocal: () -> Void

    private var messageTextColor: Color {
        message.fromMe
            ? WhatsAppVisualDesign.outgoingText
            : WhatsAppVisualDesign.primaryText
    }

    private var metadataColor: Color {
        message.fromMe
            ? WhatsAppVisualDesign.outgoingText.opacity(0.65)
            : WhatsAppVisualDesign.mutedText
    }

    private var timestamp: String {
        let raw = message.createdAt

        // Server timestamps may be seconds or milliseconds.
        let seconds: TimeInterval

        if raw > 10_000_000_000 {
            seconds = TimeInterval(raw) / 1000.0
        } else {
            seconds = TimeInterval(raw)
        }

        guard seconds > 0 else {
            return ""
        }

        let date = Date(
            timeIntervalSince1970: seconds
        )

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if message.fromMe {
                Spacer(minLength: 45)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                if !message.fromMe, let accountName, !accountName.isEmpty {
                    Text(accountName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WhatsAppVisualDesign.accent)
                        .lineLimit(1)
                }

                if let quotedText,
                   !quotedText.isEmpty {
                    quotedMessage(quotedText)
                }

                if message.deletedRemote == true {
                    deletedMessage
                } else {
                    content
                }

                HStack(spacing: 4) {
                    Spacer(minLength: 0)

                    if ultraStore.pinned(message) { Image(systemName: "pin.fill").font(.caption2).foregroundStyle(metadataColor) }
                    Text(timestamp)
                        .font(.system(size: 10))
                        .foregroundStyle(metadataColor)

                    MessageStatusIcon(
                        fromMe: message.fromMe,
                        deliveryState: message.deliveryState
                    )
                }

                if let reaction = message.reaction,
                   !reaction.isEmpty {
                    Text(reaction)
                        .font(.system(size: 16))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(
                                    Color.secondary
                                        .opacity(0.12),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 2,
                            y: 1
                        )
                        .offset(y: 10)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(
                maxWidth: ChatDesign.bubbleMaxWidth,
                alignment: .leading
            )
            .background(
                message.fromMe
                ? WhatsAppVisualDesign.outgoing
                : WhatsAppVisualDesign.incoming
            )
            .clipShape(WhatsAppVisualDesign.bubbleShape(fromMe: message.fromMe))
            .overlay {
                WhatsAppVisualDesign.bubbleShape(fromMe: message.fromMe)
                    .stroke(message.fromMe ? Color.clear : WhatsAppVisualDesign.border, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
            .contextMenu {
                Button { showReceiptInfo = true } label: { Label("פרטי הודעה", systemImage: "info.circle") }
                if !MessageMediaPolicy.isViewOnce(message) && message.deletedRemote != true {
                    Button { ultraStore.togglePin(message) } label: { Label(ultraStore.pinned(message) ? "בטל נעיצה אישית" : "נעיצה אישית", systemImage: "pin") }
                    Button { ultraForward = true } label: { Label("העבר למספר צ׳אטים", systemImage: "arrowshape.turn.up.right") }
                    if ["voice", "audio"].contains(message.type) {
                        Button { showVoiceTranscript = true } label: { Label("תמלול ותרגום ההקלטה", systemImage: "waveform.and.mic") }
                    }
                    if !message.text.isEmpty {
                        Button { Task { do { try await ultraStore.translate([message], target: "he") } catch { ultraTranslationError = error.localizedDescription } } } label: { Label("תרגם לעברית (OpenAI)", systemImage: "character.bubble") }
                    }
                }

                if MessageActionPolicy
                    .mayReply(message) {

                    Button(
                        action: onReply
                    ) {
                        Label(
                            "Reply",
                            systemImage:
                                "arrowshape.turn.up.left"
                        )
                    }
                }

                if MessageActionPolicy
                    .mayReact(message) {

                    Menu {
                        ForEach(
                            [
                                "❤️",
                                "👍",
                                "😂",
                                "😮",
                                "😢",
                                "🙏"
                            ],
                            id: \.self
                        ) { emoji in
                            Button {
                                onReact(emoji)
                            } label: {
                                Text(emoji)
                            }
                        }
                    } label: {
                        Label(
                            "React",
                            systemImage:
                                "face.smiling"
                        )
                    }
                }

                if MessageActionPolicy
                    .mayCopy(message) {

                    Button {
                        UIPasteboard
                            .general
                            .string =
                                message.text

                        Haptics.success()
                    } label: {
                        Label(
                            "Copy",
                            systemImage:
                                "doc.on.doc"
                        )
                    }
                }

                Button(
                    role: .destructive,
                    action:
                        onDeleteLocal
                ) {
                    Label(
                        "מחיקה…",
                        systemImage:
                            "trash"
                    )
                }
            }
            if !message.fromMe {
                Spacer(minLength: 45)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.vertical, 2)
        .sheet(isPresented: $ultraForward) { ForwardMessageView(message: message) }
        .sheet(isPresented: $showReceiptInfo) { MessageReceiptInfoView(message: message) }
        .sheet(isPresented: $showVoiceTranscript) { UltraVoiceTranscriptView(message: message) }
        .alert("תרגום", isPresented: Binding(get: { ultraTranslationError != nil }, set: { if !$0 { ultraTranslationError = nil } })) {
            Button("אישור", role: .cancel) {}
        } message: { Text(ultraTranslationError ?? "") }
    }

    @ViewBuilder
    private var content: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            if message.campaignReferral != nil ||
               !(message.campaignImageURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                CampaignReferralCard(
                    referral: message.campaignReferral,
                    legacyImageURL: message.campaignImageURL,
                    textColor: messageTextColor,
                    metadataColor: metadataColor
                )
            }

            if message.mediaPath != nil ||
                [
                    "image",
                    "video",
                    "video_note", "ptv",
                    "gif",
                    "voice",
                    "audio",
                    "document",
                    "view_once_image",
                    "view_once_video",
                    "view_once_audio"
                ].contains(message.type) {

                MessageMediaView(
                    message: message
                )
            }

            if let translated = ultraStore.translation(message) {
                Text(translated).font(.body).foregroundStyle(ChatDesign.accent).textSelection(.enabled)
                Text("מקור:").font(.caption2).foregroundStyle(metadataColor)
            }
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.system(size: 17))
                    .foregroundStyle(messageTextColor)
                    .textSelection(.enabled)
            }
        }
    }

    private func quotedMessage(
        _ value: String
    ) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(
                cornerRadius: 2
            )
            .fill(ChatDesign.accent)
            .frame(width: 3)

            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(7)
        .background(
            Color.primary.opacity(0.055)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 7
            )
        )
    }

    private var deletedMessage: some View {
        Label(
            "Message deleted",
            systemImage: "nosign"
        )
        .font(.subheadline.italic())
        .foregroundStyle(.secondary)
    }
}

private struct CampaignReferralCard: View {
    let referral: CampaignReferral?
    let legacyImageURL: String?
    let textColor: Color
    let metadataColor: Color

    private func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private func webURL(_ value: String?) -> URL? {
        guard let text = clean(value), let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    private var imageURL: URL? {
        webURL(referral?.originalImageURL)
            ?? webURL(referral?.thumbnailURL)
            ?? webURL(legacyImageURL)
    }

    private var thumbnailImage: UIImage? {
        guard let encoded = clean(referral?.thumbnail),
              let data = Data(base64Encoded: encoded) else { return nil }
        return UIImage(data: data)
    }

    private var destination: URL? {
        webURL(referral?.sourceURL)
            ?? webURL(referral?.adPreviewURL)
            ?? webURL(referral?.wtwaWebsiteURL)
    }

    private var sourceLabel: String {
        let isAd = referral?.showAdAttribution == true
            || clean(referral?.sourceType)?.lowercased() == "ad"
        let prefix = isAd ? "מודעה" : "מקור ההודעה"
        switch clean(referral?.sourceApp)?.lowercased() {
        case "facebook": return "\(prefix) · Facebook"
        case "instagram": return "\(prefix) · Instagram"
        case "tiktok": return "\(prefix) · TikTok"
        default: return prefix
        }
    }

    private func picture(_ image: Image) -> some View {
        image.resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var localThumbnail: some View {
        if let image = thumbnailImage {
            picture(Image(uiImage: image))
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image): picture(image)
                case .failure: localThumbnail
                case .empty:
                    if thumbnailImage != nil {
                        localThumbnail
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                    }
                @unknown default: localThumbnail
                }
            }
        } else {
            localThumbnail
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            artwork
            Label(sourceLabel, systemImage: "megaphone")
                .font(.caption.weight(.semibold))
                .foregroundStyle(metadataColor)
            if let title = clean(referral?.title) {
                Text(title).font(.subheadline.weight(.semibold))
            }
            if let body = clean(referral?.body) {
                Text(body).font(.caption)
            }
            if let destination {
                Link(destination: destination) {
                    Label("הצגת הפרטים", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                }
                .tint(ChatDesign.accent)
            }
        }
        .foregroundStyle(textColor)
        .padding(8)
        .frame(maxWidth: 280, alignment: .leading)
        .background(ChatDesign.subtleFill.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(ChatDesign.separator.opacity(0.5), lineWidth: 0.5)
        }
    }
}
