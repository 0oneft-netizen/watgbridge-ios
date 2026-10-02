import SwiftUI
import UIKit

struct ProductionComposerView: View {
    @Binding
    var text: String

    let replyingTo: Message?

    let onCancelReply: () -> Void
    let onAttachment: () -> Void
    let onCamera: () -> Void
    let onSend: () -> Void
    let onVoice: () -> Void

    @FocusState private var isFocused: Bool

    private var hasText: Bool {
        !text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if let replyingTo {
                replyPreview(replyingTo)
            }

            HStack(
                alignment: .bottom,
                spacing: 7
            ) {
                Button(
                    action: onAttachment
                ) {
                    Image(systemName: "plus")
                        .font(
                            .system(
                                size: 23,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            WhatsAppVisualDesign.accent
                        )
                        .frame(
                            width: 34,
                            height: 38
                        )
                }

                HStack(
                    alignment: .bottom,
                    spacing: 8
                ) {
                    TextField(
                        "Message",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(1...6)
                    .submitLabel(.send)
                    .font(.system(size: 17))
                    .focused($isFocused)
                    .foregroundStyle(.primary)
                    .padding(.leading, 3)
                    .padding(.vertical, 9)

                    Button(
                        action: onCamera
                    ) {
                        Image(
                            systemName:
                                "camera.fill"
                        )
                        .font(.system(size: 17))
                        .foregroundStyle(
                            WhatsAppVisualDesign.accent
                        )
                    }
                    .padding(.trailing, 2)
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 10)
                .background(
                    WhatsAppVisualDesign.background,
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                    .stroke(
                        isFocused ? WhatsAppVisualDesign.brand : WhatsAppVisualDesign.border,
                        lineWidth: 1
                    )
                }

                Button {
                    if hasText {
                        onSend()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(WhatsAppVisualDesign.brand)

                        Image(
                            systemName:
                                hasText
                                ? "arrow.up"
                                : "mic.fill"
                        )
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(
                        width: 36,
                        height: 36
                    )
                }
                .simultaneousGesture(
                    LongPressGesture(
                        minimumDuration: 0.45,
                        maximumDistance: 18
                    )
                    .onEnded { _ in
                        guard !hasText else { return }

                        let generator =
                            UIImpactFeedbackGenerator(
                                style: .medium
                            )
                        generator.impactOccurred()

                        onVoice()
                    }
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 6)
            .animation(
                .easeInOut(duration: 0.15),
                value: hasText
            )
        }
        .background(WhatsAppVisualDesign.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(WhatsAppVisualDesign.border).frame(height: 0.5)
        }
    }

    private func replyPreview(
        _ message: Message
    ) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(
                cornerRadius: 2
            )
            .fill(WhatsAppVisualDesign.accent)
            .frame(width: 3)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(
                    message.fromMe
                    ? "You"
                    : "Reply"
                )
                .font(
                    .caption
                        .weight(.semibold)
                )
                .foregroundStyle(
                    WhatsAppVisualDesign.accent
                )

                Text(
                    message.text.isEmpty
                    ? message.type
                    : message.text
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Button(
                action: onCancelReply
            ) {
                Image(
                    systemName:
                        "xmark.circle.fill"
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}
