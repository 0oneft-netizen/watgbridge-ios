import SwiftUI

struct DocumentMessageView: View {
    let message: Message

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
                .fill(
                    Color.secondary
                        .opacity(0.10)
                )

                Image(
                    systemName: "doc.fill"
                )
                .foregroundStyle(
                    ChatDesign.accent
                )
            }
            .frame(
                width: 42,
                height: 46
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    MediaFilePresentation
                        .displayName(
                            for: message
                        )
                )
                .font(
                    .subheadline.weight(
                        .medium
                    )
                )
                .lineLimit(2)

                if let ext =
                    MediaFilePresentation
                        .fileExtension(
                            for: message
                        ) {
                    Text(ext)
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }

            Spacer(minLength: 4)

            Image(
                systemName:
                    "arrow.down.circle"
            )
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            Color.secondary.opacity(0.06),
            in: RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
        )
    }
}
