import SwiftUI

enum ChatDesign {
    static let bubbleRadius: CGFloat = 12
    static let bubbleMaxWidth: CGFloat = 310

    static let incomingBubble =
        Color(uiColor: .secondarySystemBackground)

    static let outgoingBubble =
        Color(
            red: 0.82,
            green: 0.96,
            blue: 0.78
        )

    static let chatBackground =
        Color(uiColor: .systemBackground)

    static let subtleFill =
        Color(uiColor: .secondarySystemBackground)


    static let separator =
        Color(uiColor: .separator)
            .opacity(0.35)

    static let accent =
        Color(
            red: 0.10,
            green: 0.65,
            blue: 0.39
        )
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
            .font(.system(size: 10))
            .foregroundStyle(
                read
                ? ChatDesign.accent
                : .secondary
            )
        }
    }
}

struct ChatDatePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

struct SenderIdentityPill: View {
    let name: String
    let accountName: String?

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ChatDesign.accent)
                .frame(width: 7, height: 7)

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
