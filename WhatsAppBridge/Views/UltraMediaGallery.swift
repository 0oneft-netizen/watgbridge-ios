import SwiftUI
import AVKit
import Photos
import QuickLook

private struct UltraOpenMediaKey: EnvironmentKey { static let defaultValue: ((Message) -> Void)? = nil }
extension EnvironmentValues {
    var ultraOpenMedia: ((Message) -> Void)? { get { self[UltraOpenMediaKey.self] } set { self[UltraOpenMediaKey.self] = newValue } }
}
struct UltraMediaLibrary: View {
    var conversation: Conversation? = nil
    var onShow: ((Message) -> Void)? = nil
    @State private var items: [Message] = []
    @State private var account = ""
    @State private var loading = false
    @State private var more = true
    @State private var error: String?
    @State private var selected: Message?
    @ObservedObject private var sessions = SessionDirectory.shared
    var body: some View {
        ScrollView {
            if conversation == nil { Picker("חשבון", selection: $account) {
                Text("כל המספרים").tag("")
                ForEach(sessions.sessions.keys.sorted(), id: \.self) { id in Text(sessions.name(for: id)).tag(id) }
            }.pickerStyle(.menu) }
            LazyVGrid(columns: [.init(.adaptive(minimum: 105))], spacing: 4) {
                ForEach(items) { message in
                    Button { selected = message } label: {
                        VStack(spacing: 3) {
                            UltraMediaThumb(message: message).frame(height: 105).clipped()
                            Text(sessions.name(for: message.accountID)).font(.caption2).lineLimit(1)
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(6)
            if loading { ProgressView() }
            if let error { Text(error).foregroundStyle(.red) }
            if more { Button("טען קבצים קודמים") { Task { await load(reset: false) } }.disabled(loading) }
        }
        .navigationTitle("מדיה מכל המספרים")
        .task(id: account) { loading = false; await load(reset: true) }
        .fullScreenCover(item: $selected) { message in
            UltraGalleryView(initial: message, conversation: conversation, onShow: onShow)
        }
    }
    private func load(reset: Bool) async {
        if reset { items = []; more = true }
        guard !loading else { return }; loading = true; error = nil; defer { loading = false }
        let chosen = account
        do {
            let batch = try await UltraSuiteAPI.media(account: conversation == nil ? (chosen.isEmpty ? nil : chosen) : conversation?.accountID ?? "default", chat: conversation?.jid, before: reset ? nil : items.last?.id)
            guard chosen == account, !Task.isCancelled else { return }
            var existing = Set(items.map(\.id)); items.append(contentsOf: batch.messages.filter { existing.insert($0.id).inserted }); more = batch.hasMore
        } catch is CancellationError { } catch { self.error = error.localizedDescription }
    }
}
struct UltraMediaThumb: View {
    let message: Message
    var body: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            if message.type == "image", let url = APIClient.shared.mediaPreviewURL(for: message.messageID, accountID: message.accountID) {
                AsyncImage(url: url) { phase in if let image = phase.image { image.resizable().scaledToFill() } else { Image(systemName: "photo") } }
            } else { Image(systemName: message.type == "document" ? "doc.fill" : "play.rectangle.fill").font(.title) }
        }.clipped()
    }
}
struct UltraGalleryView: View {
    let initial: Message
    let conversation: Conversation?
    let onShow: ((Message) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [Message] = []
    @State private var selected: Int64
    @State private var beforeMore = true
    @State private var afterMore = true
    @State private var loading = false
    @State private var error: String?
    @State private var localURL: URL?
    @State private var actionBusy = false
    @State private var quickURL: URL?
    @State private var target: Conversation?
    init(initial: Message, conversation: Conversation?, onShow: ((Message) -> Void)?) {
        self.initial = initial; self.conversation = conversation; self.onShow = onShow
        _selected = State(initialValue: initial.id); _messages = State(initialValue: [initial])
    }
    private var current: Message { messages.first { $0.id == selected } ?? initial }
    var body: some View {
        NavigationStack {
            VStack(spacing: 4) {
                TabView(selection: $selected) {
                    ForEach(messages) { message in UltraGalleryPage(message: message, active: selected == message.id).tag(message.id) }
                }.tabViewStyle(.page(indexDisplayMode: .never))
                Text(current.text).font(.caption).lineLimit(3).padding(.horizontal)
                HStack {
                    Text("\((messages.firstIndex(where: { $0.id == selected }) ?? 0) + 1) / \(messages.count)")
                    Text(SessionDirectory.shared.name(for: current.accountID)).lineLimit(1)
                    Text(Date(timeIntervalSince1970: Double(current.createdAt > 10_000_000_000 ? current.createdAt / 1000 : current.createdAt)).formatted(date: .abbreviated, time: .shortened))
                }.font(.caption2).foregroundStyle(.secondary)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 6) {
                            ForEach(messages) { message in
                                Button { selected = message.id } label: { UltraMediaThumb(message: message).frame(width: 48, height: 48).overlay { if selected == message.id { Rectangle().stroke(.green, lineWidth: 3) } } }.id(message.id)
                            }
                        }.padding(.horizontal)
                    }.frame(height: 54).onChange(of: selected) { _, id in withAnimation { proxy.scrollTo(id, anchor: .center) } }
                }
                HStack {
                    Button("קודמות") { Task { await load(older: true) } }.disabled(!beforeMore || loading)
                    Button("הצג בשיחה") { showChat() }
                    Button("הבאות") { Task { await load(older: false) } }.disabled(!afterMore || loading)
                }.font(.caption)
                if loading || actionBusy { ProgressView() }
                if let error { Text(error).font(.caption).foregroundStyle(.red) }
            }
            .background(.black).foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() } }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { Task { await prepare() } } label: { Image(systemName: "square.and.arrow.up") }.disabled(actionBusy)
                    if let localURL { ShareLink(item: localURL) { Image(systemName: "square.and.arrow.up.fill") } }
                    if current.type != "document" { Button { Task { await save() } } label: { Image(systemName: "square.and.arrow.down") }.disabled(actionBusy) }
                }
            }.toolbarColorScheme(.dark, for: .navigationBar)
            .task { await load(older: true); await load(older: false) }
            .onChange(of: selected) { _, id in
                localURL = nil
                guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
                Task { if index < 3 { await load(older: true) }; if index > messages.count - 4 { await load(older: false) } }
            }
            .navigationDestination(item: $target) { chat in ChatView(conversation: chat, initialMessageID: current.messageID) }
        }
    }
    private func load(older: Bool) async {
        guard !loading, older ? beforeMore : afterMore else { return }; loading = true; defer { loading = false }
        do {
            let batch = try await UltraSuiteAPI.media(account: conversation == nil ? nil : initial.accountID ?? "default", chat: conversation?.jid,
                before: older ? messages.first?.id : nil, after: older ? nil : messages.last?.id)
            var values = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) }); for item in batch.messages { values[item.id] = item }
            messages = values.values.sorted {
                let a = $0.createdAt > 10_000_000_000 ? $0.createdAt / 1000 : $0.createdAt
                let b = $1.createdAt > 10_000_000_000 ? $1.createdAt / 1000 : $1.createdAt
                return a == b ? $0.id < $1.id : a < b
            }
            if older { beforeMore = batch.hasMore } else { afterMore = batch.hasMore }
            error = nil
        } catch { self.error = error.localizedDescription }
    }
    private func file(_ message: Message) async throws -> URL {
        guard !MessageMediaPolicy.isViewOnce(message), message.deletedRemote != true,
              let remote = APIClient.shared.mediaURL(for: message.messageID, accountID: message.accountID) else { throw URLError(.unsupportedURL) }
        return try await MediaCache.shared.localURL(remoteURL: remote, messageID: "\(message.accountID ?? "default")_\(message.messageID)", fileName: message.fileName, mimeType: message.mimeType, chatJID: message.chatJID)
    }
    private func prepare() async {
        actionBusy = true; defer { actionBusy = false }; let message = current
        do { let url = try await file(message); if selected == message.id { localURL = url } } catch { self.error = error.localizedDescription }
    }
    private func save() async {
        actionBusy = true; defer { actionBusy = false }
        do {
            let scope = UserWorkspace.id
            let message = current, url = try await file(message)
            guard scope == UserWorkspace.id else { throw CancellationError() }
            if message.type == "image" {
                try await PhotoLibrarySaver.saveImage(at: url, workspace: scope)
            } else {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else { throw URLError(.noPermissionsToReadFile) }
                guard scope == UserWorkspace.id else { throw CancellationError() }
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
            }
            error = "נשמר לתמונות"
        } catch { self.error = error.localizedDescription }
    }
    private func showChat() {
        if let onShow { onShow(current); dismiss() }
        else { Task { do {
            let conversations = try await APIClient.shared.fetchConversations()
            target = conversations.first { $0.jid == current.chatJID && ($0.accountID ?? "default") == (current.accountID ?? "default") }
            if target == nil { error = "השיחה לא נמצאה ברשימת השיחות" }
        } catch { self.error = error.localizedDescription } } }
    }
}
private struct UltraGalleryPage: View {
    let message: Message
    let active: Bool
    @State private var url: URL?
    @State private var image: UIImage?
    @State private var error: String?
    @State private var quick: URL?
    var body: some View {
        Group {
            if let image { ZoomableMediaImage(image: image) }
            else if let url {
                if message.type == "document" {
                    VStack { Text(message.fileName ?? "מסמך"); Button("פתח מסמך") { quick = url }; ShareLink(item: url) { Label("שיתוף", systemImage: "square.and.arrow.up") } }
                } else { UltraVideoPlayer(url: url, active: active) }
            } else if let error { Text(error).font(.caption) }
            else { ProgressView().tint(.white) }
        }.quickLookPreview($quick)
        .task(id: active ? message.id : nil) {
            guard active else { url = nil; image = nil; return }
            let scope = UserWorkspace.id
            guard !MessageMediaPolicy.isViewOnce(message), message.deletedRemote != true, let remote = APIClient.shared.mediaURL(for: message.messageID, accountID: message.accountID) else { return }
            do {
                let file = try await MediaCache.shared.localURL(remoteURL: remote, messageID: "\(message.accountID ?? "default")_\(message.messageID)", fileName: message.fileName, mimeType: message.mimeType, chatJID: message.chatJID)
                try Task.checkCancellation()
                guard scope == UserWorkspace.id else { return }
                if message.type == "image" {
                    let loaded = await ChatImageCache.shared.image(at: file)
                    try Task.checkCancellation()
                    guard scope == UserWorkspace.id else { return }
                    image = loaded
                } else { url = file }
            } catch is CancellationError { } catch { self.error = error.localizedDescription }
        }
        .onDisappear { url = nil; image = nil }
    }
}
@MainActor
struct UltraVideoPlayer: View {
    let url: URL
    var active = true
    @StateObject private var playback = ManagedVideoPlayback()
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        VStack {
            if let player = playback.player { ManagedVideoSurface(player: player) }
            else { Color.black.overlay { Image(systemName: "play.fill").foregroundStyle(.white) } }
            Slider(value: Binding(
                get: { min(playback.position, max(0.01, playback.duration)) },
                set: { playback.setScrubPosition($0) }
            ), in: 0...max(0.01, playback.duration), onEditingChanged: { playback.scrubEditing($0) })
            HStack {
                Button { playback.toggle() } label: { Image(systemName: playback.playing ? "pause.fill" : "play.fill") }
                Text("\(Int(max(0, playback.position))) / \(Int(max(0, playback.duration))) שניות").font(.caption).monospacedDigit()
                Spacer()
                Menu("\(playback.speed, specifier: "%.1f")×") {
                    ForEach([Float(0.5), 1, 1.5, 2], id: \.self) { value in
                        Button("\(value, specifier: "%.1f")×") { playback.setSpeed(value) }
                    }
                }
            }.padding(.horizontal).disabled(!active)
        }
        .task(id: active ? url : nil) {
            if active && scenePhase == .active { playback.prepare(url: url) }
            else { playback.stop() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && active { playback.prepare(url: url) }
            else { playback.stop() }
        }
        .onDisappear { playback.stop() }
    }
}
