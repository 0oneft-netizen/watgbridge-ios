import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

private struct ChatContentBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = nextValue()
    }
}

private struct ChatViewportBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = nextValue()
    }
}

struct ChatView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var sessions = SessionDirectory.shared
    @State private var workspaceScope = UserWorkspace.id
    let conversation: Conversation
    var initialMessageID: String? = nil
    @State private var requestedMessageID: String?
    private var focusMessageID: String? { requestedMessageID ?? initialMessageID }
    @State private var ultraRecents = false
    @State private var ultraTools = false
    @State private var ultraMedia: Message?
    @State private var ultraDestination: Conversation?
    @State private var autoTranslate = false
    @State private var voiceDraft: UltraVoiceDraft?
    @State private var translating = false
    @ObservedObject private var ultraQueue = UltraSendQueue.shared
    @State private var focusedContext = false
    @State private var initialFocusHandled = false
    @ObservedObject private var customerCRM = CustomerCRMDirectory.shared
    @State private var showCustomerSave = false
    @State private var outgoingCall: WhatsAppCallDestination?

    @State private var messages: [Message] = []
    @State private var isNearBottom = true
    @State private var showNewMessages = false
    @State private var chatContentBottom: CGFloat = 0
    @State private var chatViewportBottom: CGFloat = 0
    @State private var showMediaPreview = false
    @State private var mediaCaption = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var messageText = ""

    @State private var replyToMessage: Message?
    @State private var forwardMessage: Message?
    @State private var isSending = false
    @State private var isRefreshingMessages = false
    @State private var refreshPending = false
    @State private var messageCursor: Int64?
    @State private var timelineGeneration = 0
    @State private var searchTask: Task<Void, Never>?
    @State private var isSendingMedia = false
    @State private var mediaSendProgress = 0.0

    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    @State private var cameraDrafts: [UltraMediaDraft] = []
    @State private var showCameraReview = false
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
        chatCaptureContent
    }

    // Opaque view boundaries keep each SwiftUI expression small enough to type-check.
    private var chatLayout: some View {
        VStack(spacing: 0) {
            if focusedContext {
                HStack {
                    Text("ההודעה שנמצאה וההודעות הסמוכות").font(.caption)
                    Spacer()
                    Button("חזרה להודעות האחרונות") {
                        focusedContext = false; messageCursor = nil
                        Task { await loadMessages() }
                    }
                }.padding(10)
            }
            content
            composer
        }
    }

    private var chatNavigationContent: some View {
        chatLayout
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(WhatsAppVisualDesign.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                            customerCRM.name(for: conversation)
                        )
                        .font(.headline)
                        .lineLimit(1)

                        Text(sessions.name(for: conversation.accountID))
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
                Button { ultraRecents = true } label: { Image(systemName: "rectangle.stack") }
                    .accessibilityLabel("מעבר מהיר בין צ׳אטים")
                Menu {
                    Button { ultraTools = true } label: { Label("כלים, גלריה ותרגום", systemImage: "slider.horizontal.3") }
                    Button { showCustomerSave = true } label: {
                        Label("שמירה או שינוי שם לקוח", systemImage: "person.crop.circle.badge.plus")
                    }
                    Button { isSearching.toggle() } label: {
                        Label("חיפוש בשיחה", systemImage: "magnifyingglass")
                    }
                    Button { showConversationInfo = true } label: {
                        Label("פרטי איש קשר", systemImage: "info.circle")
                    }
                } label: { Image(systemName: "ellipsis") }

                Button {
                    outgoingCall = WhatsAppCallDestination(
                        accountID: conversation.accountID ?? "default",
                        chatJID: conversation.jid,
                        name: customerCRM.name(for: conversation),
                        video: true
                    )
                } label: {
                    Image(
                        systemName: "video"
                    )
                }
                .disabled(!conversation.jid.hasSuffix("@s.whatsapp.net") && !conversation.jid.hasSuffix("@lid"))
                .accessibilityLabel("שיחת וידאו עם מצלמה מקומית חסומה")

                Button {
                    outgoingCall = WhatsAppCallDestination(
                        accountID: conversation.accountID ?? "default",
                        chatJID: conversation.jid,
                        name: customerCRM.name(for: conversation),
                        video: false
                    )
                } label: {
                    Image(
                        systemName: "phone"
                    )
                }
                .disabled(!conversation.jid.hasSuffix("@s.whatsapp.net") && !conversation.jid.hasSuffix("@lid"))
                .accessibilityLabel("שיחת WhatsApp קולית")
            }
        }
    }

    private var chatWorkspaceContent: some View {
        chatNavigationContent
        .environment(\.ultraOpenMedia, { message in ultraMedia = message })
        .sheet(isPresented: $ultraRecents) {
            UltraRecentChats(current: conversation) { chat in ultraDestination = chat }
        }
        .sheet(isPresented: $ultraTools) {
            UltraChatPanel(conversation: conversation, messages: messages, autoTranslate: $autoTranslate, draftText: messageText,
                onDraft: { messageText = $0 }, onChat: { ultraDestination = $0 }, onMessage: { jumpTo($0) })
        }
        .fullScreenCover(item: $ultraMedia) { message in
            UltraGalleryView(initial: message, conversation: conversation, onShow: { jumpTo($0) })
        }
        .navigationDestination(item: $ultraDestination) { chat in ChatView(conversation: chat) }
    }

    private var chatTranslationContent: some View {
        chatWorkspaceContent
        .onChange(of: autoTranslate) { _, enabled in
            guard UserWorkspace.id == workspaceScope else { return }
            UserWorkspace.defaults.set(enabled, forKey: "ultra.translate.auto." + conversation.id)
            if enabled { Task { await translateIncoming() } }
        }
        .onChange(of: messages.last?.id) { _, _ in
            Task { guard UserWorkspace.id == workspaceScope else { return }; await UltraPreferenceStore.shared.observe(messages, chat: conversation); if autoTranslate { await translateIncoming() } }
        }
        .fullScreenCover(item: $outgoingCall) { destination in
            OutgoingWhatsAppCallView(destination: destination)
        }
        .sheet(isPresented: $showCustomerSave) {
            CustomerSaveView(conversation: conversation)
        }
    }

    private var chatSearchContent: some View {
        chatTranslationContent
        .searchable(
            text: $searchText,
            isPresented: $isSearching,
            prompt: "Search messages"
        )
        .onChange(of: searchText) {
            timelineGeneration += 1
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !query.isEmpty { focusedContext = false; initialFocusHandled = true }
                do {
                    try await Task.sleep(for: .milliseconds(220))
                    if query.isEmpty {
                        messageCursor = nil
                        await loadMessages()
                    } else {
                        let found = try await APIClient.shared.searchMessages(
                            chatJID: conversation.jid, query: query,
                            accountID: conversation.accountID ?? "default")
                        try Task.checkCancellation()
                        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
                        messages = found
                    }
                } catch is CancellationError {} catch { errorMessage = error.localizedDescription }
            }
        }
        .onDisappear { searchTask?.cancel(); recorder.cancel() }
    }

    private var chatMessageSheets: some View {
        chatSearchContent
        .sheet(item: $voiceDraft) { draft in UltraVoiceReviewView(draft: draft) { url in await sendVoice(url: url) } }
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
    }

    private var chatRealtimeContent: some View {
        chatMessageSheets
        .onReceive(
            NotificationCenter.default.publisher(
                for: .bridgeIncomingMessage
            )
        ) { notification in
            guard let incoming =
                notification.object as? RealtimeIncomingMessage
            else {
                return
            }

            let accountID =
                conversation.accountID ?? "default"

            guard incoming.account_id == accountID,
                  incoming.chat_jid == conversation.jid
            else {
                return
            }

            Task {
                await loadMessages()

                try? await APIClient.shared
                    .markRead(
                        chatJID:
                            conversation.jid,
                        accountID:
                            accountID
                    )
            }
        }

        .onReceive(
            NotificationCenter.default.publisher(
                for: .bridgeRealtimeUpdate
            )
        ) { _ in
            // Keep generic realtime events as a fallback for
            // non-message updates, but do not depend on them
            // for incoming-message delivery.
            Task {
                await loadMessages()
            }
        }
    }

    private var chatLifecycleContent: some View {
        chatRealtimeContent
        .task {
            let scope = UserWorkspace.id
            workspaceScope = scope
            UltraChatStore.shared.visit(conversation)
            autoTranslate = UserWorkspace.defaults.bool(forKey: "ultra.translate.auto." + conversation.id)
            if focusMessageID == nil,
               let cached = ChatSnapshotStore.shared.snapshot(workspace: scope,
                   account: conversation.accountID ?? "default", chat: conversation.jid) {
                messages = cached.messages; messageCursor = cached.cursor; isLoading = false
            }
            await loadMessages()
            guard UserWorkspace.id == scope, !Task.isCancelled else { return }
            try? await APIClient.shared.markRead(chatJID: conversation.jid,
                accountID: conversation.accountID ?? "default")
        }
        .task(id: conversation.id) {
            let scope = workspaceScope
            do { let pref = try await UltraPreferenceStore.shared.load(conversation); guard UserWorkspace.id == scope else { return }; autoTranslate = pref.autoTranslate } catch { }
            guard UserWorkspace.id == scope, !Task.isCancelled else { return }
            await UltraPreferenceStore.shared.observe(messages, chat: conversation)
            if autoTranslate { await translateIncoming() }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            RealtimeClient.shared.start()
            // Fallback only while this chat is visible and the app is in the foreground.
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(8)) } catch { return }
                guard UserWorkspace.id == workspaceScope else { return }
                await loadMessages()
            }
        }
        .alert(
            "עדכון בשיחה",
            isPresented: Binding(
                get: {
                    errorMessage != nil &&
                    !messages.isEmpty
                },
                set: { presented in
                    if !presented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var chatPhotoContent: some View {
        chatLifecycleContent
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
        .sheet(isPresented: $showMediaPreview, onDismiss: { selectedPhotoItems = [] }) {
            UltraMediaComposer(items: selectedPhotoItems, conversation: conversation) {
                selectedPhotoItems = []; mediaCaption = ""; showMediaPreview = false
                Task { await loadMessages() }
            }
        }
    }

    private var chatCaptureContent: some View {
        chatPhotoContent
        .sheet(
            isPresented: $showCamera
        ) {
            CameraPicker(
                onImage: { image in
                    Task {
                        await prepareCamera(image: image, video: nil)
                    }
                },
                onVideo: { url in
                    Task {
                        await prepareCamera(image: nil, video: url)
                    }
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showCameraReview, onDismiss: { cameraDrafts = [] }) {
            UltraMediaComposer(items: [], seeded: cameraDrafts, conversation: conversation) {
                showCameraReview = false; Task { await loadMessages() }
            }
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
                    if !focusedContext, !messages.isEmpty,
                       searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       (conversation.jid.hasSuffix("@s.whatsapp.net") || conversation.jid.hasSuffix("@lid")),
                       messages.contains(where: { !$0.fromMe }),
                       customerCRM.customer(for: conversation) == nil {
                        NewSenderContactCard(conversation: conversation,
                            onSave: { showCustomerSave = true },
                            onDetails: { showConversationInfo = true })
                            .padding(.horizontal, ConversationDesign.horizontalInset)
                    }
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
                        .background(message.messageID == focusMessageID && focusedContext ? ChatDesign.accent.opacity(0.13) : Color.clear)
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

                .padding(.horizontal, 10)
                .padding(.vertical, 10)

                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ChatContentBottomPreferenceKey.self,
                            value: geometry.frame(
                                in: .named("chat-scroll")
                            ).maxY
                        )
                }
                .frame(height: 1)
                .id("chat-bottom-sentinel")
            }
            .coordinateSpace(name: "chat-scroll")
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ChatViewportBottomPreferenceKey.self,
                            value: geometry.frame(
                                in: .named("chat-scroll")
                            ).maxY
                        )
                }
            )
            .onAppear {
                if focusedContext, let target = messages.first(where: { $0.messageID == focusMessageID }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { proxy.scrollTo(target.id, anchor: .center) }
                }
            }
            .onChange(of: focusedContext) { _, focused in
                if focused, let target = messages.first(where: { $0.messageID == focusMessageID }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { proxy.scrollTo(target.id, anchor: .center) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            .refreshable {
                await loadMessages()
            }
            .onPreferenceChange(
                ChatContentBottomPreferenceKey.self
            ) { value in
                chatContentBottom = value

                updateChatBottomState()
            }
            .onPreferenceChange(
                ChatViewportBottomPreferenceKey.self
            ) { value in
                chatViewportBottom = value

                updateChatBottomState()
            }
            .onChange(
                of: messages.last?.id
            ) {
                if focusedContext {
                    if let target = messages.first(where: { $0.messageID == focusMessageID }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { proxy.scrollTo(target.id, anchor: .center) }
                    }
                    return
                }
                guard let last = messages.last else {
                    return
                }

                if isNearBottom {
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(
                            last.id,
                            anchor: .bottom
                        )
                    }

                    showNewMessages = false
                } else {
                    showNewMessages = true
                }
            }
            .overlay(alignment: .bottom) {
                if showNewMessages {
                    Button {
                        isNearBottom = true
                        showNewMessages = false

                        if let last = messages.last {
                            withAnimation(
                                .easeOut(duration: 0.22)
                            ) {
                                proxy.scrollTo(
                                    last.id,
                                    anchor: .bottom
                                )
                            }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(
                                systemName:
                                    "arrow.down"
                            )

                            Text("הודעות חדשות")
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .semibold
                                    )
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.regularMaterial)
                        .clipShape(
                            Capsule()
                        )
                        .shadow(
                            radius: 8,
                            y: 3
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                    .transition(
                        .move(edge: .bottom)
                        .combined(
                            with: .opacity
                        )
                    )
                    .zIndex(10)
                }
            }
            .onAppear {
                let route =
                    ChatRouteIdentity(
                        conversation:
                            conversation
                    )

                if messageText.isEmpty {
                    messageText =
                        ChatDraftStore
                            .shared
                            .text(
                                accountID:
                                    route.accountID,
                                chatJID:
                                    route.chatJID
                            )
                }

                isNearBottom = true
                showNewMessages = false
                scrollToBottom(proxy)
            }
        }
                    .background {
                        ChatBackgroundView()
                    }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            UltraLinkPreview(text: messageText)
            let pending = ultraQueue.items.filter { $0.account == (conversation.accountID ?? "default") && $0.chat == conversation.jid && $0.state != "sent" }
            if !pending.isEmpty {
                Button { ultraTools = true } label: {
                    Label("\(pending.count) הודעות בתור · פתח כלים לבדיקת שליחה", systemImage: "tray.and.arrow.up")
                        .font(.caption).padding(8)
                }
            }
            if recorder.isRecording {
                recordingBar
            }

            ProductionComposerView(
                text: $messageText,
                isSending: isSending || isSendingMedia,
                isRecording: recorder.isRecording,
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

                voiceDraft = UltraVoiceDraft(url: url)
            }
        )
    }

    @MainActor





    private func toggleProductionRecording() {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            voiceDraft = UltraVoiceDraft(url: url)
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

    @MainActor
    private func loadProductionMessages() async { await loadMessages() }


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

        guard !items.isEmpty else {
            isSendingMedia = false
            return
        }

        defer {
            selectedPhotoItems = []
            isSendingMedia = false
            mediaSendProgress = 0
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
    ) async -> Bool {
        guard UserWorkspace.id == workspaceScope else { return false }
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
            return true

        } catch {
            errorMessage =
                error.localizedDescription
            return false
        }
    }

    @MainActor
    private func loadMessages() async {
        let scope = workspaceScope
        guard UserWorkspace.id == scope, scope != "signed-out" else { return }
        if focusedContext { return }
        if let id = focusMessageID, !initialFocusHandled {
            guard !isRefreshingMessages else { return }
            isRefreshingMessages = true; isLoading = true
            defer { isRefreshingMessages = false; isLoading = false }
            do {
                let found = try await CustomerFeaturesAPI.shared.context(conversation, messageID: id)
                try Task.checkCancellation()
                guard UserWorkspace.id == scope else { return }
                focusedContext = true; initialFocusHandled = true
                isNearBottom = false; messages = found; errorMessage = nil
            } catch { errorMessage = error.localizedDescription }
            return
        }
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if isRefreshingMessages { refreshPending = true; return }
        isRefreshingMessages = true
        defer { isRefreshingMessages = false; isLoading = false }
        if messages.isEmpty { isLoading = true }
        repeat {
            refreshPending = false
            let generation = timelineGeneration
            let clock = ContinuousClock()
            let start = clock.now
            do {
                let batch = try await APIClient.shared.syncMessages(
                    chatJID: conversation.jid,
                    accountID: conversation.accountID ?? "default", cursor: messageCursor)
                try Task.checkCancellation()
                guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                if generation != timelineGeneration { refreshPending = true; continue }
                guard UserWorkspace.id == scope else { return }
                let latest = MessageTimelineMerge.apply(batch, to: messages)
                if latest != messages { messages = latest }
                messageCursor = batch.cursor
                ChatSnapshotStore.shared.save(workspace: scope, account: conversation.accountID ?? "default",
                    chat: conversation.jid, messages: messages, cursor: batch.cursor)
                ChatPerformanceMonitor.synced(changed: batch.messages.count, reset: batch.reset, duration: start.duration(to: clock.now))
                errorMessage = nil
            } catch is CancellationError { return }
              catch { errorMessage = error.localizedDescription; return }
        } while refreshPending && !Task.isCancelled
    }

    @MainActor private func prepareCamera(image: UIImage?, video: URL?) async {
        let scope = UserWorkspace.id
        do {
            let url: URL
            if let image {
                url = UltraMediaEditing.temporary("jpg")
                guard let data = image.jpegData(compressionQuality: 0.96) else { throw URLError(.cannotCreateFile) }
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } else if let video {
                url = UltraMediaEditing.temporary(video.pathExtension.isEmpty ? "mov" : video.pathExtension)
                try FileManager.default.copyItem(at: video, to: url)
            } else { return }
            guard scope == UserWorkspace.id else { try? FileManager.default.removeItem(at: url); return }
            cameraDrafts = [.init(original: url, current: url, isVideo: video != nil, originalName: "camera." + url.pathExtension, originalMime: video == nil ? "image/jpeg" : "video/quicktime")]
            showCamera = false
            try await Task.sleep(for: .milliseconds(350))
            guard scope == UserWorkspace.id else { try? FileManager.default.removeItem(at: url); cameraDrafts = []; return }
            showCameraReview = true
        } catch { errorMessage = error.localizedDescription }
    }

    private func jumpTo(_ message: Message) {
        requestedMessageID = message.messageID; initialFocusHandled = false
        focusedContext = false; messageCursor = nil; ultraTools = false
        Task { await loadMessages() }
    }
    @MainActor private func translateIncoming() async {
        guard autoTranslate, !translating, UserWorkspace.id == workspaceScope else { return }; translating = true; defer { translating = false }
        let pending = messages.filter { !$0.fromMe && !$0.text.isEmpty && $0.deletedRemote != true && UltraChatStore.shared.translation($0) == nil }.suffix(12)
        do { try await UltraChatStore.shared.translate(Array(pending), target: "he") }
        catch { errorMessage = "התרגום לא הושלם: " + error.localizedDescription }
    }

    private func updateChatBottomState() {
        guard chatContentBottom > 0,
              chatViewportBottom > 0
        else {
            return
        }

        let distance =
            chatContentBottom - chatViewportBottom

        let nearBottom =
            distance <= 80

        if isNearBottom != nearBottom {
            isNearBottom = nearBottom
        }

        if nearBottom && showNewMessages {
            withAnimation(.easeOut(duration: 0.15)) {
                showNewMessages = false
            }
        }
    }

    private func scrollToBottom(
        _ proxy: ScrollViewProxy
    ) {
        guard let last =
                messages.last
        else {
            return
        }

        isNearBottom = true
        showNewMessages = false

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
