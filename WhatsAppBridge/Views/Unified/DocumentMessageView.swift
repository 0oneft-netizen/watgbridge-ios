import SwiftUI
import QuickLook

struct DocumentMessageView: View {
    let url: URL
    let fileName: String?
    let mimeType: String?

    @State private var previewURL: URL?

    private var title: String {
        guard let fileName, !fileName.isEmpty else {
            return "Document"
        }
        return fileName
    }

    private var subtitle: String {
        if let mimeType, !mimeType.isEmpty {
            return mimeType
        }

        let ext = url.pathExtension.uppercased()
        return ext.isEmpty ? "File" : ext
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 46, height: 52)

                Image(systemName: icon)
                    .font(.title2)
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Menu {
                Button {
                    previewURL = url
                } label: {
                    Label("Open", systemImage: "doc.text.magnifyingglass")
                }

                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .padding(10)
        .frame(minWidth: 220, maxWidth: 290)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            previewURL = url
        }
        .quickLookPreview($previewURL)
    }

    private var icon: String {
        let value = (
            mimeType ?? url.pathExtension
        ).lowercased()

        if value.contains("pdf") {
            return "doc.richtext.fill"
        }

        if value.contains("zip") ||
            value.contains("archive") {
            return "doc.zipper"
        }

        if value.contains("sheet") ||
            value.contains("excel") ||
            value.contains("csv") {
            return "tablecells.fill"
        }

        if value.contains("presentation") ||
            value.contains("powerpoint") {
            return "rectangle.on.rectangle.angled"
        }

        return "doc.fill"
    }
}
