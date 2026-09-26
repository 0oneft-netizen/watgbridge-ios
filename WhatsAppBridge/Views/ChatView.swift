import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ChatView: View {
    let conversation: Conversation

    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var messageText = ""
    @State private var replyToMessage: Message?
    @State private var forwardMessage: Message?
    @State private var isSending = false
    @State private var isRefreshingMessages = false
    @State private var isSendingMedia = false
    @State private var mediaSendProgress = 0.0

    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    @State private var showPhotos = false
    @State private var showCamera = false
    @State private var showFiles = false
    @State private var showAttachmentMenu = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showConversationInfo = false


    @StateObject
    private var recorder = AudioRecorder()

    var body: some View {
        VStack(spacing: 0) {
            content
            composer
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .principal
            ) {
                HStack(spacing: 8) {
                    Button {
                        showConversationInfo = true
                    } label: {
                        ChatAvatar(
                            conversation: conversation
                        )
                    }
                    .buttonStyle(.plain)

                    VStack(
                        alignment: .leading,
                        spacing: 1
                    ) {
                        Text(
                            conversation.displayName
                        )
                        .font(.headline)
                        .lineLimit(1)

                        Text("WhatsApp")
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
            }

            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                Button {
                    isSearching.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                } label: {
                    Image(
                        systemName: "video"
                    )
                }

                Button {
                } label: {
                    Image(
                        systemName: "phone"
                    )
                }
            }
        }
        .searchable(
            text: $searchText,
            isPresented: $isSearching,
            prompt: "Search messages"
        )
        .onChange(of: searchText) {
            Task {
                let normalizedSearch =
                    searchText.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                if normalizedSearch.isEmpty {
                    await loadMessages()
                } else {
                    do {
                        messages = try await APIClient.shared
                            .searchMessages(
                    chatJID: conversation.jid,
                    query: normalizedSearch,
                    accountID:
                        conversation.accountID ?? "default"
                )
                    } catch {
                    }
                }
            }
        }
        .sheet(
            isPresented: $showConversationInfo
        ) {
            NavigationStack {
                CustomerProfileView(
                    conversation: conversation,
                    messages: messages
                )
            }
        }
        .sheet(
            item: $forwardMessage
        ) { message in
            ForwardMessageView(
                message: message
            )
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .bridgeRealtimeUpdate
            )
        ) { notification in
            Task {
                await loadMessages()

                try? await APIClient.shared
                    .markRead(
                        chatJID:
                            conversation.jid,
                        accountID:
                            conversation.accountID ?? "default"
                    )
            }
        }
        .task {
            try? await APIClient.shared
                .markRead(
                    chatJID:
                        conversation.jid,
                    accountID:
                        conversation.accountID ?? "default"
                )

            await loadMessages()

            while !Task.isCancelled {
                try? await Task.sleep(
                    for: .seconds(1)
                )

                await loadMessages()

                try? await APIClient.shared
                    .markRead(
                        chatJID:
                            conversation.jid,
                        accountID:
                            conversation.accountID ?? "default"
                    )
            }
        }
        .photosPicker(
            isPresented: $showPhotos,
            selection: $selectedPhotoItems,
            maxSelectionCount: 20,
            matching: .any(
                of: [
                    .images,
                    .videos
                ]
            )
        )
        .onChange(
            of: selectedPhotoItems
        ) {
            if !selectedPhotoItems.isEmpty {
                showMediaPreview = true
            }
        }
        .sheet(
            isPresented: $showMediaPreview
        ) {
            MediaSendPreview(
                items: selectedPhotoItems,
                caption: $mediaCaption,
                onCancel: {
                    selectedPhotoItems = []
                    mediaCaption = ""
                    showMediaPreview = false
                },
                onSend: {
                    showMediaPreview = false
                    Task {
                        await sendSelectedMediaItems()
                    }
                }
            )
        }
        .sheet(
            isPresented: $showCamera
        ) {
            CameraPicker(
                onImage: { image in
                    Task {
                        await sendCameraImage(image)
                    }
                },
                onVideo: { url in
                    Task {
                        await sendCameraVideo(url)
                    }
                }
            )
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $showFiles,
            allowedContentTypes: [
                .item
            ],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleFileResult(
                    result
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading &&
            messages.isEmpty {

            ProgressView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

        } else if let errorMessage,
                  messages.isEmpty {

            ContentUnavailableView(
                "Couldn't Load Messages",
                systemImage:
                    "wifi.exclamationmark",
                description:
                    Text(errorMessage)
            )

        } else {
            messageList
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: ConversationDesign.messageSpacing) {
                    ForEach(
                        Array(messages.enumerated()),
                        id: \.element.id
                    ) { index, message in

                        let previous =
                            index > 0
                            ? messages[index - 1]
                            : nil

                        let next =
                            index + 1 < messages.count
                            ? messages[index + 1]
                            : nil

                        if MessageGrouping.needsDateSeparator(
                            message,
                            previous: previous
                        ) {
                            ChatDateChip(
                                timestamp:
                                    message.createdAt
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                        }

                        ProductionMessageBubble(
                            message: message,
                            messages: messages,
                            beginsGroup:
                                MessageGrouping.beginsGroup(
                                    message,
                                    previous: previous
                                ),
                            endsGroup:
                                MessageGrouping.endsGroup(
                                    message,
                                    next: next
                                ),
                            onReply: {
                                replyToMessage = message
                            },
                            onReact: { emoji in
                                reactToProductionMessage(
                                    message,
                                    emoji: emoji,
                                )
                            },
                            onDelete: {
                                deleteProductionMessage(
                                    message
                                )
                            }
                        )
                        .id(message.id)
                        .padding(
                            .horizontal,
                            ConversationDesign.horizontalInset
                        )
                        .padding(
                            .vertical,
                            MessageGrouping.endsGroup(
                                message,
                                next: next
                            ) ? 3 : 0
                        )
}
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }

            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            .refreshable {
                await loadMessages()
            }
            .onChange(
                of: messages.last?.id
            ) {
                guard let last = messages.last else {
                    return
                }

                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo(
                        last.id,
                        anchor: .bottom
                    )
                }
            }
            .onAppear {
                scrollToBottom(proxy)
            }
        }
                    .background {
                        ChatBackgroundView()
                    }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            if recorder.isRecording {
                recordingBar
            }

            ProductionComposerView(
                text: $messageText,
                replyingTo: replyToMessage,
                onCancelReply: {
                    replyToMessage = nil
                },
                onAttachment: {
                    showAttachmentMenu = true
                },
                onCamera: {
                    showCamera = true
                },
                onSend: {
                    sendProductionMessage()
                },
                onVoice: {
                    toggleProductionRecording()
                }
            )
        }
        .confirmationDialog(
            "Attach",
            isPresented:
                $showAttachmentMenu,
            titleVisibility: .hidden
        ) {
            Button("Photos & Videos") {
                showPhotos = true
            }

            Button("Camera") {
                showCamera = true
            }

            Button("Document") {
                showFiles = true
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}
        }
    }

    private var recordingBar: some View {
        HStack {
            Circle()
                .fill(.red)
                .frame(
                    width: 9,
                    height: 9
                )

            Text(
                recorder.elapsed,
                format:
                    .number.precision(
                        .fractionLength(1)
                    )
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Recording voice message")
                    .font(.subheadline.weight(.medium))

                Text("Tap the microphone again to send")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                recorder.cancel()
            } label: {
                Image(systemName: "trash")
                    .font(.headline)
            }
            .foregroundStyle(.red)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var micButton: some View {
        Image(
            systemName:
                recorder.isRecording
                ? "stop.circle.fill"
                : "mic.fill"
        )
        .font(.title2)
        .foregroundStyle(
            recorder.isRecording
            ? .red
            : .primary
        )
        .frame(
            width: 36,
            height: 36
        )
        .contentShape(
            Circle()
        )
        .gesture(
            DragGesture(
                minimumDistance: 0
            )
            .onChanged { _ in
                if !recorder.isRecording {
                    Task {
                        try? await recorder
                            .start()
                    }
                }
            }
            .onEnded { _ in
                guard recorder.isRecording,
                      let url =
                        recorder.stop()
                else {
                    return
                }

                Task {
                    await sendVoice(
                        url: url
                    )
                }
            }
        )
    }

    @MainActor





    private func toggleProductionRecording() {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            Task { await sendVoice(url: url) }
        } else {
            Task {
                do {
                    try await recorder.start()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }


    private func reactToProductionMessage(
        _ message: Message,
        emoji: String
    ) {
        let messageID =
            message.messageID

        let accountID =
            message.accountID
            ?? "default"

        Task {
            try? await APIClient.shared
                .react(
                    messageID: messageID,
                    chatJID: message.chatJID,
                    emoji: emoji,
                    accountID: accountID
                )
        }
    }


    private func sendProductionMessage() {
        let text = messageText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            return
        }

        guard !isSending else {
            return
        }

        let accountID =
            conversation.accountID
            ?? "default"

        let chatJID =
            conversation.jid

        let reply =
            replyToMessage

        isSending = true

        Task {
            do {
                if let reply {
                    try await APIClient.shared
                        .sendReply(
                            chatJID: chatJID,
                            text: text,
                            replyTo: reply,
                            accountID: accountID
                        )
                } else {
                    try await APIClient.shared
                        .sendMessage(
                            chatJID: chatJID,
                            text: text,
                            accountID: accountID
                        )
                }

                await MainActor.run {
                    messageText = ""
                    replyToMessage = nil
                    isSending = false
                }

                await loadProductionMessages()
            } catch {
                await MainActor.run {
                    errorMessage =
                        error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func loadProductionMessages()
        async {

        let accountID =
            conversation.accountID
            ?? "default"

        do {
            let latest =
                try await APIClient.shared
                    .fetchMessages(
                        chatJID:
                            conversation.jid,
                        accountID:
                            accountID
                    )

            await MainActor.run {
                messages = latest
            }
        } catch {
            // Keep current timeline visible.
        }
    }


    private func deleteProductionMessage(
        _ message: Message
    ) {
        let messageID =
            message.messageID

        let accountID =
            message.accountID
            ?? "default"

        Task {
            try? await APIClient.shared
                .deleteLocal(
                    messageID: messageID,
                    accountID: accountID
                )

            await MainActor.run {
                messages.removeAll {
                    item in

                    item.messageID
                        == messageID
                }
            }
        }
    }


    private func unifiedSenderName(
        for message: Message
    ) -> String {
        if message.fromMe {
            return "You"
        }

        let jid = message.senderJID

        if let at = jid.firstIndex(of: "@") {
            return String(jid[..<at])
        }

        return jid
    }

    private func unifiedQuotedText(
        for message: Message
    ) -> String? {
        guard let replyID = message.replyToID,
              !replyID.isEmpty
        else {
            return nil
        }

        if let original = messages.first(
            where: {
                $0.messageID == replyID
            }
        ) {
            if !original.text.isEmpty {
                return original.text
            }

            return original.type
                .replacingOccurrences(
                    of: "_",
                    with: " "
                )
                .capitalized
        }

        return "Reply"
    }


    private func sendText() async {
        let text =
            messageText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard !text.isEmpty,
              !isSending
        else {
            return
        }

        isSending = true

        do {
            if let reply = replyToMessage {
                try await APIClient.shared
                    .sendReply(
                        chatJID:
                            conversation.jid,
                        text: text,
                        replyTo: reply,
                    accountID:
                        conversation.accountID ?? "default"
                    )
            } else {
                try await APIClient.shared
                    .sendMessage(
                        chatJID:
                            conversation.jid,
                        text: text,
                        accountID:
                            conversation.accountID ?? "default"
                    )
            }

            messageText = ""
            replyToMessage = nil

            await loadMessages()

        } catch {
            errorMessage =
                error.localizedDescription
        }

        isSending = false
    }

    @MainActor
    private func sendSelectedMediaItems()
        async {
        guard !isSendingMedia else { return }
        isSendingMedia = true
        mediaSendProgress = 0



        let items = selectedPhotoItems
        let caption = mediaCaption

        guard !items.isEmpty else { return }

        defer {
            selectedPhotoItems = []
        }

        for item in items {
        do {
            guard let data =
                    try await item
                        .loadTransferable(
                            type: Data.self
                        )
            else {
                return
            }

            let type =
                item.supportedContentTypes
                    .first

            let mime =
                type?.preferredMIMEType
                ?? "application/octet-stream"

            let isVideo =
                item.supportedContentTypes
                    .contains {
                        $0.conforms(
                            to: .movie
                        )
                    }

            let ext =
                type?.preferredFilenameExtension
                ?? (isVideo
                    ? "mov"
                    : "jpg")

            try await APIClient.shared
                .sendMedia(
                    chatJID:
                        conversation.jid,
                    type:
                        isVideo
                        ? "video"
                        : "image",
                    data: data,
                    filename:
                        "media.\(ext)",
                    mimeType: mime,
                    caption: item == items.first ? caption : "",
                    accountID: conversation.accountID ?? "default"
                )


        } catch {
            errorMessage =
                error.localizedDescription
        }
        }

        mediaCaption = ""
        await loadMessages()
    }

    @MainActor
    private func sendCameraImage(
        _ image: UIImage
    ) async {

        guard let data =
                image.jpegData(
                    compressionQuality: 0.88
                )
        else {
            return
        }

        do {
            try await APIClient.shared
                .sendMedia(
                    chatJID:
                        conversation.jid,
                    type: "image",
                    data: data,
                    filename: "camera.jpg",
                    mimeType: "image/jpeg",
                    accountID: conversation.accountID ?? "default"
                )

            await loadMessages()

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    @MainActor
    private func sendCameraVideo(
        _ url: URL
    ) async {
        do {
            let data = try Data(contentsOf: url)

            try await APIClient.shared.sendMedia(
                chatJID: conversation.jid,
                type: "video",
                data: data,
                filename: "camera.mov",
                mimeType: "video/quicktime",
                accountID:
                    conversation.accountID ?? "default"
            )

            await loadMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func handleFileResult(
        _ result:
            Result<[URL], Error>
    ) async {

        do {
            let urls = try result.get()

            guard let url = urls.first
            else {
                return
            }

            let accessed =
                url.startAccessingSecurityScopedResource()

            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data =
                try Data(
                    contentsOf: url
                )

            let values =
                try? url.resourceValues(
                    forKeys: [
                        .contentTypeKey
                    ]
                )

            let mime =
                values?.contentType?
                    .preferredMIMEType
                ?? "application/octet-stream"

            try await APIClient.shared
                .sendMedia(
                    chatJID:
                        conversation.jid,
                    type: "document",
                    data: data,
                    filename:
                        url.lastPathComponent,
                    mimeType: mime,
                    accountID: conversation.accountID ?? "default"
                )

            await loadMessages()

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    @MainActor
    private func sendVoice(
        url: URL
    ) async {

        defer {
            try? FileManager.default
                .removeItem(at: url)
        }

        do {
            let data =
                try Data(
                    contentsOf: url
                )

            try await APIClient.shared
                .sendMedia(
                    chatJID:
                        conversation.jid,
                    type: "voice",
                    data: data,
                    filename:
                        "voice.m4a",
                    mimeType:
                        "audio/mp4",
                    accountID: conversation.accountID ?? "default"
                )

            await loadMessages()

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    @MainActor
    private func loadMessages()
        async {

        guard !isRefreshingMessages else {
            return
        }

        isRefreshingMessages = true

        defer {
            isRefreshingMessages = false
        }

        if messages.isEmpty {
            isLoading = true
        }

        do {
            let fetched =
                try await APIClient.shared
                    .fetchMessages(
                        chatJID:
                            conversation.jid,
                        accountID:
                            conversation.accountID ?? "default"
                    )

            errorMessage = nil

        } catch {
            errorMessage =
                error.localizedDescription
        }

        isLoading = false
    }

    private func scrollToBottom(
        _ proxy: ScrollViewProxy
    ) {
        guard let last =
                messages.last
        else {
            return
        }

        DispatchQueue.main
            .asyncAfter(
                deadline:
                    .now() + 0.05
            ) {
                proxy.scrollTo(
                    last.id,
                    anchor: .bottom
                )
            }
    }
}


private struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.fromMe {
                Spacer(
                    minLength: 50
                )
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                if let replyID = message.replyToID,
                   !replyID.isEmpty {
                    HStack(spacing: 5) {
                        Rectangle()
                            .frame(
                                width: 3,
                                height: 30
                            )
                            .foregroundStyle(.green)

                        VStack(
                            alignment: .leading,
                            spacing: 1
                        ) {
                            Text("Reply")
                                .font(
                                    .caption
                                        .weight(.semibold)
                                )

                            Text(replyID)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(6)
                    .background(
                        Color.secondary
                            .opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 7
                        )
                    )
                }

                if message.type != "text" {
                    MessageMediaView(
                        message: message
                    )
                }

                if !message.text.isEmpty {
                    Text(message.text)
                }

                if message.deletedRemote == true {
                    Label(
                        "Deleted on WhatsApp",
                        systemImage: "trash.slash"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                if let reaction = message.reaction,
                   !reaction.isEmpty {
                    Text(reaction)
                        .font(.title3)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    Color.secondary
                                        .opacity(0.12)
                                )
                        )
                }

                HStack(spacing: 4) {
                    Spacer(
                        minLength: 0
                    )

                    Text(timeText)
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )

                    if message.fromMe {
                        Image(
                            systemName:
                                "checkmark.2"
                        )
                        .font(
                            .caption2
                                .weight(
                                    .semibold
                                )
                        )
                        .foregroundStyle(
                            .blue
                        )
                    }
                }
            }
            .padding(
                .horizontal,
                10
            )
            .padding(
                .vertical,
                7
            )
            .background(
                message.fromMe
                ? Color.green
                    .opacity(0.22)
                : Color(
                    .secondarySystemBackground
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .frame(
                maxWidth: 310,
                alignment:
                    message.fromMe
                    ? .trailing
                    : .leading
            )

            if !message.fromMe {
                Spacer(
                    minLength: 50
                )
            }
        }
    }

    private var timeText: String {
        Date(
            timeIntervalSince1970:
                TimeInterval(
                    message.createdAt
                )
        )
        .formatted(
            date: .omitted,
            time: .shortened
        )
    }
}


private struct ChatAvatar: View {
    let conversation: Conversation

    var body: some View {
        Group {
            if let url =
                APIClient.shared
                    .avatarURL(
                        for:
                            conversation.jid
                    ) {

                AsyncImage(
                    url: url
                ) { phase in
                    switch phase {
                    case .success(
                        let image
                    ):
                        image
                            .resizable()
                            .scaledToFill()

                    default:
                        fallback
                    }
                }

            } else {
                fallback
            }
        }
        .frame(
            width: 32,
            height: 32
        )
        .clipShape(
            Circle()
        )
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(
                    Color.secondary
                        .opacity(0.18)
                )

            Text(
                conversation.initials
            )
            .font(
                .caption
                    .weight(
                        .semibold
                    )
            )
        }
    }
}
