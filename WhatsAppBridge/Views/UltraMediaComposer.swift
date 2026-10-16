import SwiftUI
import PhotosUI
import AVKit
import ImageIO

struct UltraMediaComposer: View {
    let items: [PhotosPickerItem]
    var seeded: [UltraMediaDraft] = []
    let conversation: Conversation
    let onSent: () -> Void
    private let userScope = UserWorkspace.id
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [UltraMediaDraft] = []
    @State private var quality = UltraMediaQuality.high
    @State private var error: String?
    @State private var loading = true
    @State private var sending = false
    @State private var progress = 0
    @State private var editing: UltraMediaDraft?
    @State private var estimated: Int?
    @State private var generation = UUID()
    @State private var sendTask: Task<Void, Never>?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("איכות", selection: $quality) { ForEach(UltraMediaQuality.allCases) { Text($0.title).tag($0) } }
                    if let estimated { Text("גודל מוכן לשליחה: \(ByteCountFormatter.string(fromByteCount: Int64(estimated), countStyle: .file))").font(.caption) }
                    Text("גרור לשינוי הסדר. הכיתוב של כל פריט יישלח איתו. התמונות יישלחו ברצף לפי הסדר שבחרת.").font(.caption).foregroundStyle(.secondary)
                    if quality == .original { Text("תמונה מקורית ללא עריכה נשלחת כמסמך כדי לשמור את הבתים המקוריים. עריכה מחייבת יצירת קובץ חדש.").font(.caption).foregroundStyle(.secondary) }
                }
                ForEach($drafts) { $draft in
                    VStack(alignment: .leading, spacing: 8) {
                        UltraDraftThumb(url: draft.current, video: draft.isVideo).frame(height: 120)
                        HStack {
                            Image(systemName: draft.isVideo ? "video.fill" : "photo.fill")
                            Text("\((drafts.firstIndex(where: { $0.id == draft.id }) ?? 0) + 1). \(draft.isVideo ? "סרטון" : "תמונה")")
                            Spacer()
                            Button("עריכה") { editing = draft }.disabled(sending)
                        }
                        TextField("כיתוב לפריט", text: $draft.caption, axis: .vertical)
                            .disabled(sending)
                    }.padding(.vertical, 6)
                }.onMove { drafts.move(fromOffsets: $0, toOffset: $1); estimated = nil }.onDelete { indices in
                    for i in indices { clean(drafts[i]) }; drafts.remove(atOffsets: indices); estimated = nil
                }.deleteDisabled(sending).moveDisabled(sending)
                if loading { ProgressView("טוען קבצים…") }
                if sending { ProgressView("מוסיף לתור \(progress) מתוך \(drafts.count)") }
                if let error { Text(error).foregroundStyle(.red) }
                Section {
                    Button("חשב גודל לפני השליחה") { Task { await estimate() } }.disabled(loading || sending || drafts.isEmpty)
                    Button("שלח לפי הסדר שנבחר") { sendTask = Task { await send() } }.disabled(loading || sending || drafts.isEmpty)
                }
            }
            .environment(\.editMode, .constant(sending ? .inactive : .active))
            .navigationTitle("אלבום ועריכת מדיה")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() }.disabled(sending) } }
            .interactiveDismissDisabled(sending)
            .sheet(item: $editing) { draft in
                if draft.isVideo {
                    UltraVideoEditor(draft: draft, quality: quality) { edited in replace(edited) }
                } else {
                    UltraPhotoEditor(draft: draft) { edited in replace(edited) }
                }
            }
            .task {
                do { drafts = seeded.isEmpty ? try await UltraMediaEditing.load(items) : seeded } catch { self.error = error.localizedDescription }; loading = false
            }
            .onChange(of: quality) { _, _ in estimated = nil }
            .onDisappear { generation = UUID(); sendTask?.cancel(); for draft in drafts { clean(draft) } }
        }
    }
    private func replace(_ draft: UltraMediaDraft) {
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            let old = drafts[index]; if old.current != old.original && old.current != draft.current { try? FileManager.default.removeItem(at: old.current) }
            drafts[index] = draft; estimated = nil
        }
    }
    private func clean(_ draft: UltraMediaDraft) {
        try? FileManager.default.removeItem(at: draft.original)
        if draft.current != draft.original { try? FileManager.default.removeItem(at: draft.current) }
    }
    private func estimate() async {
        sending = true; defer { sending = false }; error = nil
        do { var total = 0; for draft in drafts { let file = try await UltraMediaEditing.prepare(draft, quality: quality); total += file.data.count }; estimated = total } catch { self.error = error.localizedDescription }
    }
    private func send() async {
        guard !sending, userScope == UserWorkspace.id else { return }; sending = true; error = nil; progress = 0
        let scope = UserWorkspace.id, token = generation
        var submitted = Set<UUID>()
        do {
            for draft in drafts {
                try Task.checkCancellation(); guard scope == UserWorkspace.id, token == generation else { throw CancellationError() }
                let file = try await UltraMediaEditing.prepare(draft, quality: quality)
                try await APIClient.shared.sendMedia(chatJID: conversation.jid, type: file.type, data: file.data, filename: file.filename, mimeType: file.mime, caption: file.caption, accountID: conversation.accountID ?? "default")
                submitted.insert(draft.id); progress += 1
            }
            onSent(); dismiss()
        } catch {
            // Preserve unsent files; submitting the album again must not resend its successful prefix.
            for draft in drafts where submitted.contains(draft.id) { clean(draft) }
            drafts.removeAll { submitted.contains($0.id) }
            self.error = error.localizedDescription
        }
        sending = false
    }
}

struct UltraVideoEditor: View {
    let draft: UltraMediaDraft
    let quality: UltraMediaQuality
    let onSave: (UltraMediaDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var duration = 1.0
    @State private var start = 0.0
    @State private var end = 1.0
    @State private var coverTime = 0.0
    @State private var cover: Data?
    @State private var mute = false
    @State private var turns = 0
    @State private var busy = false
    @State private var error: String?
    @State private var player: AVPlayer?
    var body: some View {
        NavigationStack {
            Form {
                if let player { VideoPlayer(player: player).frame(height: 240) }
                Section("חיתוך בשניות") {
                    Text("תחילה: \(start, specifier: "%.1f")"); Slider(value: $start, in: 0...max(0.01, end - 0.1))
                    Text("סיום: \(end, specifier: "%.1f")"); Slider(value: $end, in: min(start + 0.1, duration)...max(duration, start + 0.1))
                    Button("נגן מהתחלה שנבחרה") { player?.seek(to: CMTime(seconds: start, preferredTimescale: 600)); player?.play() }
                }
                Toggle("הסרת קול מהסרטון", isOn: $mute)
                Button("סיבוב: \((turns % 4) * 90)°") { turns += 1 }
                Section("תמונת פתיחה") {
                    Slider(value: $coverTime, in: 0...max(0.01, duration - 0.05))
                    Button("בחר את הפריים הזה") { Task {
                        do { cover = try await UltraMediaEditing.poster(draft.current, seconds: coverTime) } catch { self.error = error.localizedDescription }
                    } }
                    if let cover, let image = UIImage(data: cover) { Image(uiImage: image).resizable().scaledToFit().frame(height: 120); Button("הסר תמונת פתיחה") { self.cover = nil } }
                    Text("התמונה משולבת בפריימים הראשונים של הסרטון. תצוגת התמונה הממוזערת במכשיר הנמען נקבעת גם על ידי WhatsApp.").font(.caption).foregroundStyle(.secondary)
                }
                if busy { ProgressView("מייצא סרטון…") }
                if let error { Text(error).foregroundStyle(.red) }
            }.disabled(busy)
            .navigationTitle("עריכת סרטון")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("ביטול") { dismiss() }.disabled(busy) }
                ToolbarItem(placement: .topBarTrailing) { Button("שמור") { Task { await save() } }.disabled(busy) }
            }.interactiveDismissDisabled(busy)
            .task {
                player = AVPlayer(url: draft.current)
                do { let loadedDuration = try await AVURLAsset(url: draft.current).load(.duration); let seconds = loadedDuration.seconds; if seconds.isFinite && seconds > 0 { duration = seconds; end = seconds } } catch { self.error = error.localizedDescription }
            }.onDisappear { player?.pause(); player = nil }
        }
    }
    private func save() async {
        busy = true; player?.pause(); defer { busy = false }
        do {
            let source = draft.current, begin = start, finish = end, muted = mute, rotation = turns, chosen = cover, mode = UltraMediaQuality.original
            let url = try await Task.detached { try await UltraMediaEditing.exportVideo(source, start: begin, end: finish, mute: muted, turns: rotation, quality: mode, cover: chosen) }.value
            var edited = draft; edited.current = url; edited.edited = true; edited.cover = cover; onSave(edited); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

private struct UltraDraftThumb: View {
    let url: URL
    let video: Bool
    @State private var image: UIImage?
    var body: some View {
        Group { if let image { Image(uiImage: image).resizable().scaledToFit() } else { Image(systemName: video ? "video" : "photo").font(.largeTitle).foregroundStyle(.secondary) } }
        .task(id: url) {
            if video {
                let data = try? await UltraMediaEditing.poster(url, seconds: 0)
                if let data { image = UIImage(data: data) }
            } else {
                image = await Task.detached {
                    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                        let preview = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: 512] as CFDictionary) else { return nil as UIImage? }
                    return UIImage(cgImage: preview)
                }.value
            }
        }
    }
}
