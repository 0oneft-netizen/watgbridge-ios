import SwiftUI
import PhotosUI
import AVKit

struct MediaSendPreview: View {
    let items: [PhotosPickerItem]
    @Binding var caption: String
    let onCancel: () -> Void
    let onSend: () -> Void

    @State private var previews: [PreviewMedia] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if loading {
                        ProgressView()
                    } else if previews.isEmpty {
                        ContentUnavailableView(
                            "Unable to preview media",
                            systemImage: "photo.badge.exclamationmark"
                        )
                    } else {
                        TabView {
                            ForEach(previews) { preview in
                                previewView(preview)
                                    .padding()
                            }
                        }
                        .tabViewStyle(.page)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if previews.count > 1 {
                    Text("\(previews.count) items selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)
                }

                HStack(spacing: 12) {
                    TextField(
                        "Add a caption…",
                        text: $caption,
                        axis: .vertical
                    )
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)

                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                    }
                    .disabled(previews.isEmpty)
                }
                .padding()
            }
            .background(Color.black.opacity(0.96))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .principal) {
                    Text("Preview")
                        .font(.headline)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadPreviews()
            }
        }
    }

    @ViewBuilder
    private func previewView(
        _ preview: PreviewMedia
    ) -> some View {
        switch preview.kind {
        case .image:
            if let image = UIImage(data: preview.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

        case .video:
            if let url = preview.fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @MainActor
    private func loadPreviews() async {
        var result: [PreviewMedia] = []

        for item in items {
            guard let data = try? await item.loadTransferable(
                type: Data.self
            ) else {
                continue
            }

            let isVideo = item.supportedContentTypes.contains {
                $0.conforms(to: .movie)
            }

            if isVideo {
                let ext =
                    item.supportedContentTypes.first?
                        .preferredFilenameExtension ?? "mov"

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(
                        "preview-\(UUID().uuidString).\(ext)"
                    )

                try? data.write(to: url)

                result.append(
                    PreviewMedia(
                        data: data,
                        kind: .video,
                        fileURL: url
                    )
                )
            } else {
                result.append(
                    PreviewMedia(
                        data: data,
                        kind: .image,
                        fileURL: nil
                    )
                )
            }
        }

        previews = result
        loading = false
    }
}

private struct PreviewMedia: Identifiable {
    enum Kind {
        case image
        case video
    }

    let id = UUID()
    let data: Data
    let kind: Kind
    let fileURL: URL?
}
