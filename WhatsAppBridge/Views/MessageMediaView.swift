import SwiftUI
import AVKit
import Photos
import UIKit

struct MessageMediaView: View {
    let message: Message

    @State private var showViewer = false

    private var mediaURL: URL? {
        APIClient.shared.mediaURL(
            for: message.messageID,
            accountID: message.accountID
        )
    }

    var body: some View {
        if let url = mediaURL {
            switch message.type {

            case "image":
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: 250,
                                height: 250
                            )
                            .clipped()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showViewer = true
                            }
                            .fullScreenCover(
                                isPresented: $showViewer
                            ) {
                                MediaViewer(
                                    message: message,
                                    url: url,
                                    kind: .image
                                )
                            }

                    case .failure:
                        placeholder(
                            "Photo",
                            icon: "photo"
                        )

                    default:
                        ProgressView()
                            .frame(
                                width: 250,
                                height: 180
                            )
                    }
                }

            case "video", "gif":
                ZStack {
                    VideoPlayer(
                        player: AVPlayer(url: url)
                    )
                    .allowsHitTesting(false)

                    Image(
                        systemName:
                            "arrow.up.left.and.arrow.down.right"
                    )
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(9)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
                }
                .frame(
                    width: 250,
                    height: 190
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    showViewer = true
                }
                .fullScreenCover(
                    isPresented: $showViewer
                ) {
                    MediaViewer(
                        message: message,
                        url: url,
                        kind: .video
                    )
                }

            case "video_note":
                ZStack {
                    VideoPlayer(
                        player: AVPlayer(url: url)
                    )
                    .allowsHitTesting(false)

                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
                .frame(
                    width: 210,
                    height: 210
                )
                .clipShape(Circle())
                .contentShape(Circle())
                .onTapGesture {
                    showViewer = true
                }
                .fullScreenCover(
                    isPresented: $showViewer
                ) {
                    MediaViewer(
                        message: message,
                        url: url,
                        kind: .video
                    )
                }

            case "voice":
                AudioMessageView(
                    url: url,
                    isVoice: true
                )

            case "audio":
                AudioMessageView(
                    url: url,
                    isVoice: false
                )

            case "document":
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.fill")
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text(
                                message.fileName?
                                    .isEmpty == false
                                ? message.fileName!
                                : "Document"
                            )
                            .font(
                                .subheadline
                                    .weight(.semibold)
                            )
                            .lineLimit(2)

                            if let mime = message.mimeType,
                               !mime.isEmpty {
                                Text(mime)
                                    .font(.caption2)
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }
                        }

                        Spacer()

                        Image(
                            systemName:
                                "arrow.down.circle"
                        )
                    }
                    .padding(10)
                    .background(
                        Color.secondary
                            .opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )
                }

            case "view_once_image",
                 "view_once_video",
                 "view_once_audio":
                Label(
                    "View once",
                    systemImage: "1.circle"
                )
                .font(.subheadline.weight(.semibold))
                .padding(10)

            default:
                placeholder(
                    message.type.capitalized,
                    icon: "paperclip"
                )
            }

        } else if message.type != "text" {
            placeholder(
                message.type.capitalized,
                icon: "paperclip"
            )
        }
    }

    private func placeholder(
        _ title: String,
        icon: String
    ) -> some View {
        Label(
            title,
            systemImage: icon
        )
        .frame(
            minWidth: 160,
            minHeight: 44
        )
    }
}

private enum MediaViewerKind {
    case image
    case video
}

private struct MediaViewer: View {
    let message: Message
    let url: URL
    let kind: MediaViewerKind

    @Environment(\.dismiss)
    private var dismiss

    @State private var localFileURL: URL?
    @State private var isDownloading = false
    @State private var statusText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                switch kind {
                case .image:
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity
                                )

                        case .failure:
                            ContentUnavailableView(
                                "Unable to load photo",
                                systemImage: "photo"
                            )
                            .foregroundStyle(.white)

                        default:
                            ProgressView()
                                .tint(.white)
                        }
                    }

                case .video:
                    VideoPlayer(
                        player: AVPlayer(url: url)
                    )
                    .ignoresSafeArea(
                        edges: .bottom
                    )
                }
            }
            .toolbar {
                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    Button {
                        Task {
                            await saveToPhotos()
                        }
                    } label: {
                        Image(
                            systemName:
                                "square.and.arrow.down"
                        )
                    }
                    .disabled(isDownloading)

                    if let localFileURL {
                        ShareLink(item: localFileURL) {
                            Image(
                                systemName:
                                    "square.and.arrow.up"
                            )
                        }
                    } else {
                        Button {
                            Task {
                                await prepareShare()
                            }
                        } label: {
                            Image(
                                systemName:
                                    "square.and.arrow.up"
                            )
                        }
                        .disabled(isDownloading)
                    }
                }
            }
            .toolbarBackground(
                .black,
                for: .navigationBar
            )
            .toolbarColorScheme(
                .dark,
                for: .navigationBar
            )
            .overlay(alignment: .bottom) {
                if let statusText {
                    Text(statusText)
                        .font(.footnote)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
            }
        }
    }

    @MainActor
    private func prepareShare() async {
        do {
            localFileURL =
                try await downloadToTemporaryFile()
            statusText = "Ready to share"
        } catch {
            statusText =
                "Could not prepare media"
        }
    }

    @MainActor
    private func saveToPhotos() async {
        guard !isDownloading else {
            return
        }

        isDownloading = true
        defer {
            isDownloading = false
        }

        do {
            let file =
                try await downloadToTemporaryFile()

            localFileURL = file

            let permission =
                await PHPhotoLibrary.requestAuthorization(
                    for: .addOnly
                )

            guard permission == .authorized ||
                  permission == .limited else {
                statusText =
                    "Photo permission is required"
                return
            }

            try await PHPhotoLibrary.shared()
                .performChanges {
                    switch kind {
                    case .image:
                        if let data =
                            try? Data(
                                contentsOf: file
                            ),
                           let image =
                            UIImage(data: data) {
                            PHAssetChangeRequest
                                .creationRequestForAsset(
                                    from: image
                                )
                        }

                    case .video:
                        PHAssetChangeRequest
                            .creationRequestForAssetFromVideo(
                                atFileURL: file
                            )
                    }
                }

            statusText = "Saved to Photos"

        } catch {
            statusText = "Could not save media"
        }
    }

    private func downloadToTemporaryFile()
        async throws -> URL {

        let (temporaryURL, response) =
            try await URLSession.shared
                .download(from: url)

        guard let http =
                response as? HTTPURLResponse,
              (200...299)
                .contains(http.statusCode)
        else {
            throw URLError(
                .badServerResponse
            )
        }

        var ext =
            (message.fileName as NSString?)
                ?.pathExtension ?? ""

        if ext.isEmpty {
            switch kind {
            case .image:
                ext = "jpg"
            case .video:
                ext = "mp4"
            }
        }

        let destination =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    UUID().uuidString
                )
                .appendingPathExtension(ext)

        if FileManager.default
            .fileExists(
                atPath: destination.path
            ) {
            try FileManager.default
                .removeItem(
                    at: destination
                )
        }

        try FileManager.default
            .moveItem(
                at: temporaryURL,
                to: destination
            )

        return destination
    }
}
