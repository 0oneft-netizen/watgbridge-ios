import SwiftUI
import UIKit

enum AppVisualDesign {
    static let accent = Color(
        red: 0.10,
        green: 0.65,
        blue: 0.39
    )

    static let outgoingBubble = Color(
        red: 0.82,
        green: 0.96,
        blue: 0.78
    )

    static let incomingBubble =
        Color(uiColor: .secondarySystemBackground)

    static let screenBackground =
        Color(uiColor: .systemBackground)

    static let chatBackgroundLight = Color(
        red: 0.94,
        green: 0.92,
        blue: 0.88
    )

    static let chatBackgroundDark = Color(
        red: 0.055,
        green: 0.075,
        blue: 0.075
    )

    static let composerBackground =
        Color(uiColor: .systemBackground)

    static let composerField =
        Color(uiColor: .secondarySystemBackground)

    static let separator =
        Color(uiColor: .separator).opacity(0.35)

    static let avatarFill =
        Color.secondary.opacity(0.13)

    static let outgoingText = Color(
        red: 0.06,
        green: 0.10,
        blue: 0.07
    )

    static let outgoingMetadata =
        Color.black.opacity(0.52)

    static let bubbleRadius: CGFloat = 16
    static let bubbleMaximumWidth: CGFloat = 310

    static let avatarSize: CGFloat = 52
    static let chatAvatarSize: CGFloat = 38

    static let rowVerticalPadding: CGFloat = 8
    static let screenHorizontalPadding: CGFloat = 16
}

struct AppAvatarPlaceholder: View {
    let initials: String
    var size: CGFloat = AppVisualDesign.avatarSize

    var body: some View {
        ZStack {
            Circle()
                .fill(AppVisualDesign.avatarFill)

            Image(systemName: "person.fill")
                .font(
                    .system(
                        size: size * 0.48,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary.opacity(0.65))

            if !initials.isEmpty {
                Text(initials)
                    .font(
                        .system(
                            size: max(10, size * 0.22),
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.secondary)
                    .offset(y: size * 0.28)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SessionMiniBadge: View {
    let name: String

    var body: some View {
        if !name.isEmpty {
            HStack(spacing: 4) {
                Circle()
                    .fill(AppVisualDesign.accent)
                    .frame(width: 5, height: 5)

                Text(name)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)
        }
    }
}
