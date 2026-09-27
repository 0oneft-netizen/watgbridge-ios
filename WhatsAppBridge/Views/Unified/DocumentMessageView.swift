import SwiftUI

struct DocumentMessageView: View {
    let message: Message

    private var title: String {
        let value =
            message.fileName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            ?? ""

        return value.isEmpty
            ? "Document"
            : value
    }

    private var detail: String {
        guard
            let mime = message.mimeType,
            !mime.isEmpty
        else {
            return "File"
        }

        return mime
            .split(separator: "/")
            .last
            .map(String.init)?
            .uppercased()
            ?? "File"
    }

    var body: some View {
        HStack(spacing: 10) {
            MessageFileIcon(
                mimeType:
                    message.mimeType
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .lineLimit(2)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Image(
                systemName:
                    "arrow.down.circle"
            )
            .font(
                .system(
                    size: 20,
                    weight: .regular
                )
            )
            .foregroundStyle(
                AppVisualDesign.accent
            )
        }
        .padding(9)
        .frame(
            minWidth: 220
        )
        .background(
            Color.primary
                .opacity(0.055),
            in:
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
        )
    }
}
