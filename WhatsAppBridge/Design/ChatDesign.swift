import SwiftUI
import UIKit

enum ChatDesign {
    static let bubbleRadius =
        AppVisualDesign.bubbleRadius

    static let bubbleMaxWidth =
        AppVisualDesign.bubbleMaximumWidth

    static let incomingBubble =
        AppVisualDesign.incomingBubble

    static let outgoingBubble =
        AppVisualDesign.outgoingBubble

    static let chatBackground =
        AppVisualDesign.screenBackground

    static let subtleFill =
        Color(uiColor: .secondarySystemBackground)

    static let separator =
        AppVisualDesign.separator

    static let accent =
        AppVisualDesign.accent
}

struct ChatBubbleShape: Shape {
    let fromMe: Bool

    func path(in rect: CGRect) -> Path {
        let radius = ChatDesign.bubbleRadius

        var corners: UIRectCorner = [
            .topLeft,
            .topRight,
            .bottomLeft,
            .bottomRight
        ]

        if fromMe {
            corners.remove(.bottomRight)
        } else {
            corners.remove(.bottomLeft)
        }

        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: radius,
                height: radius
            )
        )

        return Path(path.cgPath)
    }
}

struct MessageStatusIcon: View {
    let fromMe: Bool
    let read: Bool

    var body: some View {
        if fromMe {
            Image(
                systemName:
                    read
                    ? "checkmark.circle.fill"
                    : "checkmark"
            )
            .font(
                .system(
                    size: 10,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                read
                ? ChatDesign.accent
                : AppVisualDesign.outgoingMetadata
            )
        }
    }
}

struct ChatDatePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
            )
            .shadow(
                color: .black.opacity(0.05),
                radius: 1,
                y: 1
            )
    }
}

struct SenderIdentityPill: View {
    let name: String
    let accountName: String?

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ChatDesign.accent)
                .frame(width: 6, height: 6)

            Text(name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            if let accountName,
               !accountName.isEmpty {
                Text("•")
                    .foregroundStyle(.tertiary)

                Text(accountName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct UnreadBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text(
                count > 99
                ? "99+"
                : "\(count)"
            )
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(minWidth: 20, minHeight: 20)
            .background(ChatDesign.accent)
            .clipShape(Capsule())
        }
    }
}
