import SwiftUI
import AVKit
import Photos
import UIKit

struct MessageMediaView: View {
    let message: Message

    @State private var showViewer = false
    @State private var localURL: URL?
    @State private var loadError = false
    @State private var isLoading = false

    private var remoteURL: URL? {
        APIClient.shared.mediaURL(
            for: message.messageID,
            accountID: message.accountID
        )
    }

    private var isViewOnce: Bool {
        message.type == "view_once_image" ||
        message.type == "view_once_video" ||
        message.type == "view_once_audio"
    }

    private var isSupportedMedia: Bool {
        switch message.type {
        case "image", "video", "gif", "video_note", "ptv",
             "voice", "audio", "document",
             "view_once_image", "view_once_video",
             "view_once_audio":
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    var body: some View {
        if !isSupportedMedia {
            EmptyView()
        } else if MessageMediaPolicy.isViewOnce(
            message
        ) {
            ViewOnceMessageView()
        } else {
            Group {
                if let url = localURL {
                    loadedMedia(url: url)

                } else if loadError {
                    Button {
                        Task {
                            await loadMedia(
                                force: true
                            )
                        }
                    } label: {
                        Label(
                            "Media unavailable · Tap to retry",
                            systemImage:
                                "arrow.clockwise"
                        )
                        .frame(
                            minWidth: 160,
                            minHeight: 54
                        )
                    }
                    .buttonStyle(.plain)

                } else {
                    ProgressView()
                        .frame(
                            minWidth: 160,
                            minHeight: 80
                        )
                }
            }
            .task(id: message.messageID) {
                await loadMedia()
            }
        }
    }

    @ViewBuilder
    private func loadedMedia(
        url: URL
    ) -> some View {
        switch message.type {
        case "image":
            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
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
            } else {
                mediaPlaceholder(
                    "Unable to load photo",
                    icon: "photo"
                )
            }

        case "video", "gif":
            ZStack {
                VideoPlayer(
                    player: AVPlayer(url: url)
                )
                .allowsHitTesting(false)

                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(
                        .black.opacity(0.45)
                    )
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

        case "video_note", "ptv":
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
            DocumentMessageView(message: message)

        default:
            mediaPlaceholder(
                message.type.capitalized,
                icon: "paperclip"
            )
        }
    }

    private func mediaPlaceholder(
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

    @MainActor
    private func loadMedia(
        force: Bool = false
    ) async {
        guard isSupportedMedia else {
            return
        }

        guard !isViewOnce else {
            return
        }

        if localURL != nil && !force {
            return
        }

        guard !isLoading,
              let remoteURL
        else {
            loadError = true
            return
        }

        isLoading = true
        loadError = false

        defer {
            isLoading = false
        }

        do {
            let result =
                try await MediaCache.shared.localURL(
                    remoteURL: remoteURL,
                    messageID:
                        "\(message.accountID ?? "default")_\(message.messageID)",
                    fileName: message.fileName,
                    mimeType: message.mimeType
                )

            localURL = result
        } catch {
            print(
                "[MEDIA] load failed",
                message.messageID,
                error.localizedDescription
            )

            loadError = true
        }
    }
}


private struct ConversationMediaViewer: View {
    let initialMessage: Message
    let messages: [Message]

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedID: Int64

    init(
        initialMessage: Message,
        messages: [Message]
    ) {
        self.initialMessage = initialMessage
        self.messages = messages

        _selectedID = State(
            initialValue: initialMessage.id
        )
    }

    private var mediaMessages: [Message] {
        let source =
            messages.isEmpty
            ? [initialMessage]
            : messages

        let filtered =
            ConversationMediaFilter.filter(
                source,
                kind: .all
            )
            .filter {
                MediaActionPolicy.allowsGallery(
                    message: $0
                )
            }

        // Defensive fallback: opening an ordinary media message
        // must still work if the caller only has that message.
        if filtered.contains(
            where: { $0.id == initialMessage.id }
        ) {
            return filtered
        }

        guard
            !MessageMediaPolicy.isViewOnce(
                initialMessage
            )
        else {
            return filtered
        }

        return filtered + [initialMessage]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if mediaMessages.isEmpty {
                    ContentUnavailableView(
                        "Media unavailable",
                        systemImage: "photo.on.rectangle"
                    )
                    .foregroundStyle(.white)
                } else {
                    TabView(selection: $selectedID) {
                        ForEach(
                            mediaMessages,
                            id: \.id
                        ) { item in
                            ConversationMediaPage(
                                message: item
                            )
                            .tag(item.id)
                        }
                    }
                    .tabViewStyle(
                        .page(
                            indexDisplayMode: .never
                        )
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

                ToolbarItem(
                    placement: .principal
                ) {
                    if let index =
                        mediaMessages.firstIndex(
                            where: {
                                $0.id == selectedID
                            }
                        ) {
                        Text(
                            "\(index + 1) / \(mediaMessages.count)"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
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
        }
    }
}

private struct ConversationMediaPage: View {
    let message: Message

    @State private var localURL: URL?
    @State private var loadError = false

    private var kind: MediaViewerKind {
        switch message.type.lowercased() {
        case "image":
            return .image
        default:
            return .video
        }
    }

    var body: some View {
        Group {
            if MessageMediaPolicy.isViewOnce(
                message
            ) {
                // Second boundary. View Once must never enter
                // this ordinary cached/exportable viewer.
                ContentUnavailableView(
                    "View Once",
                    systemImage: "eye.slash"
                )
                .foregroundStyle(.white)

            } else if let localURL {
                MediaViewer(
                    message: message,
                    url: localURL,
                    kind: kind
                )

            } else if loadError {
                ContentUnavailableView(
                    "Media unavailable",
                    systemImage:
                        "exclamationmark.triangle"
                )
                .foregroundStyle(.white)

            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: message.id) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard
            !MessageMediaPolicy.isViewOnce(
                message
            ),
            MediaActionPolicy.allowsGallery(
                message: message
            )
        else {
            return
        }

        guard let remoteURL =
            APIClient.shared.mediaURL(
                for: message.messageID,
                accountID: message.accountID
            )
        else {
            loadError = true
            return
        }

        do {
            localURL =
                try await MediaCache.shared.localURL(
                    remoteURL: remoteURL,
                    messageID:
                        "\(message.accountID ?? "default")_\(message.messageID)",
                    fileName: message.fileName,
                    mimeType: message.mimeType
                )
        } catch {
            loadError = true
        }
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
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        ZoomableMediaImage(image: image)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                    } else {
                        ContentUnavailableView(
                            "Unable to load photo",
                            systemImage: "photo"
                        )
                        .foregroundStyle(.white)
                    }

                case .video:
                    MediaVideoPlayer(url: url)
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
            if url.isFileURL {
                localFileURL = url
            } else {
                localFileURL =
                    try await downloadToTemporaryFile()
            }

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
            // The viewer now receives a local cached file.
            // Reuse it instead of downloading /media again.
            let file: URL

            if url.isFileURL {
                file = url
            } else {
                file = try await downloadToTemporaryFile()
            }

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

        var ext = ""

        if let fileName = message.fileName,
           !fileName.isEmpty {
            ext = (fileName as NSString).pathExtension
        }

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
