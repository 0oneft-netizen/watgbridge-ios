import SwiftUI

@MainActor struct UltraStorageView: View {
    @ObservedObject private var pins = UltraChatStore.shared
    @ObservedObject private var stars = StarredMessageStore.shared
    @State private var chats: [UltraCacheChat] = []
    @State private var scanning = false
    @State private var scanned = 0
    @State private var message: String?
    @State private var scope = UserWorkspace.id
    private var protectedKeys: Set<String> { stars.keys.union(pins.pins.map { ($0.accountID ?? "default") + "|" + $0.messageID }) }
    var body: some View {
        List {
            Section {
                Text("עותקי מדיה מקומיים לפי צ׳אט. קבצים שסומנו לשמירה, כוכב או נעיצה אישית מוגנים מניקוי. ההודעות והקבצים בשרת אינם נמחקים. הסריקה ממפה קבצים שיש להם הודעה זמינה בשרת; קבצים שלא זוהו נשארים באייפון.").font(.footnote)
                LabeledContent("מדיה שמופתה באייפון", value: ByteCountFormatter.string(fromByteCount: chats.reduce(0) { $0 + $1.bytes }, countStyle: .file))
                Button(scanning ? "ממפה… \(scanned) הודעות" : "סרוק עותקים קיימים לפי הצ׳אטים") { Task { await scan() } }.disabled(scanning)
                if scanning { ProgressView() }
                if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
            ForEach(chats) { chat in
                NavigationLink {
                    UltraChatStorageDetail(account: chat.account, chat: chat.chat)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name(chat))
                        Text(SessionDirectory.shared.name(for: chat.account)).font(.caption)
                        Text("\(chat.files.count) קבצים · \(ByteCountFormatter.string(fromByteCount: chat.bytes, countStyle: .file))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("אחסון לפי צ׳אט")
        .task { await refresh(); if chats.isEmpty { await scan() } }
        .refreshable { await refresh() }
    }
    private func name(_ chat: UltraCacheChat) -> String {
        pins.recents.first(where: { $0.id == chat.id })?.conversation.displayName ?? chat.chat.components(separatedBy: "@").first ?? chat.chat
    }
    private func refresh() async { chats = await MediaCache.shared.storageChats(workspace: scope, protectedKeys: protectedKeys) }
    private func scan() async {
        guard !scanning else { return }; scanning = true; scanned = 0; defer { scanning = false }
        var after: Int64 = 0
        do {
            for _ in 0..<100 {
                try Task.checkCancellation()
                let batch: UltraStorageInventory = try await UltraCompleteAPI.request("features/storage-inventory", workspace: scope, query: [.init(name: "after", value: String(after))])
                try await MediaCache.shared.indexStorage(batch.items, workspace: scope, server: UserWorkspace.serverURL)
                scanned += batch.items.count; await refresh()
                if !batch.hasMore { message = "המיפוי הושלם. קבצים שאינם קיימים באייפון לא הורדו."; return }
                guard batch.after > after else { throw URLError(.cannotParseResponse) }; after = batch.after
            }
            message = "מופו עד 100,000 הודעות. ייתכן שהיסטוריה נוספת עדיין לא מוצגת."
        } catch is CancellationError { }
        catch { message = "הסריקה לא הושלמה. הקבצים שכבר מופו זמינים; אפשר לסרוק שוב." }
    }
}

@MainActor private struct UltraChatStorageDetail: View {
    let account: String, chat: String
    @ObservedObject private var pins = UltraChatStore.shared
    @ObservedObject private var stars = StarredMessageStore.shared
    @State private var files: [UltraCacheFile] = []
    @State private var confirm = false
    @State private var busy = false
    @State private var message: String?
    @State private var scope = UserWorkspace.id
    private var protectedKeys: Set<String> { stars.keys.union(pins.pins.map { ($0.accountID ?? "default") + "|" + $0.messageID }) }
    var body: some View {
        List {
            Section {
                Text(SessionDirectory.shared.name(for: account)).font(.headline)
                Text(chat).font(.caption).textSelection(.enabled)
                Button("מחק עותקים מקומיים שאינם מוגנים", role: .destructive) { confirm = true }.disabled(busy || files.allSatisfy(\.protected))
                Text("סימון שמירה מגן מהניקוי באפליקציה. אחסון מטמון עדיין עשוי להתפנות על ידי iOS; לשמירה עצמאית השתמש גם בשיתוף לקבצים או לתמונות.").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(files) { file in
                VStack(alignment: .leading, spacing: 5) {
                    Text(file.entry.name).lineLimit(2)
                    Text(ByteCountFormatter.string(fromByteCount: file.bytes, countStyle: .file)).font(.caption)
                    if file.protected { Label("מוגן מניקוי", systemImage: "lock.fill").font(.caption) }
                    if protectedKeys.contains(file.entry.key) { Text("מוגן באמצעות כוכב או נעיצה אישית").font(.caption).foregroundStyle(.secondary) }
                    Button(file.entry.kept ? "בטל סימון שמירה" : "שמור מפני ניקוי") { Task { await keep(file) } }.disabled(busy)
                }
            }
            if let message { Text(message) }
        }.navigationTitle("קבצי הצ׳אט").task { await refresh() }
        .confirmationDialog("למחוק את העותקים המקומיים שאינם מוגנים?", isPresented: $confirm, titleVisibility: .visible) {
            Button("מחק עותקים מקומיים", role: .destructive) { Task { await clean() } }
        } message: { Text("אפשר להוריד שוב מדיה שנותרה זמינה בשרת. קבצים מוגנים נשארים.") }
    }
    private func refresh() async { let chats = await MediaCache.shared.storageChats(workspace: scope, protectedKeys: protectedKeys); files = chats.first(where: { $0.account == account && $0.chat == chat })?.files ?? [] }
    private func keep(_ file: UltraCacheFile) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { try await MediaCache.shared.keepStorageFile(file.id, workspace: scope, kept: !file.entry.kept); await refresh() } catch { message = "לא ניתן לשנות את סימון השמירה." }
    }
    private func clean() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let removed = try await MediaCache.shared.cleanStorage(workspace: scope, account: account, chat: chat, protectedKeys: protectedKeys); message = "פונו \(ByteCountFormatter.string(fromByteCount: removed, countStyle: .file))"; await refresh() } catch { message = "הניקוי לא הושלם. אפשר לרענן ולבדוק את הקבצים שנותרו." }
    }
}
