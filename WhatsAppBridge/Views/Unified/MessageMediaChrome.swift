import SwiftUI

struct MessageMediaChrome<Content: View>: View {
    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
            )
    }
}

struct MessageMediaTypeBadge: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)

            Text(title)
        }
        .font(
            .system(
                size: 10,
                weight: .semibold
            )
        )
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            .black.opacity(0.55),
            in: Capsule()
        )
    }
}

struct MessageFileIcon: View {
    let mimeType: String?

    private var symbol: String {
        guard let mimeType else {
            return "doc.fill"
        }

        let mime =
            mimeType.lowercased()

        if mime.contains("pdf") {
            return "doc.richtext.fill"
        }

        if mime.contains("image") {
            return "photo.fill"
        }

        if mime.contains("audio") {
            return "waveform"
        }

        if mime.contains("video") {
            return "video.fill"
        }

        if mime.contains("zip")
            || mime.contains("archive") {
            return "archivebox.fill"
        }

        return "doc.fill"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 9,
                style: .continuous
            )
            .fill(
                AppVisualDesign
                    .accent
                    .opacity(0.12)
            )

            Image(
                systemName: symbol
            )
            .font(
                .system(
                    size: 20,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                AppVisualDesign.accent
            )
        }
        .frame(
            width: 42,
            height: 42
        )
    }
}
