import SwiftUI

struct CustomerContactControls: View {
    let conversation: Conversation
    @State private var state: CustomerContactState?
    @State private var busy = false
    @State private var error: String?
    @State private var confirmBlock = false
    private var identity: [URLQueryItem] {
        [URLQueryItem(name: "account_id", value: conversation.accountID ?? "default"), URLQueryItem(name: "jid", value: conversation.jid)]
    }
    var body: some View {
        Form {
            Section {
                Text(CustomerCRMDirectory.shared.name(for: conversation)).font(.headline)
                Text("הוואטסאפ: \(SessionDirectory.shared.name(for: conversation.accountID))").font(.caption)
                if let state {
                    LabeledContent("חסימה ב־WhatsApp", value: state.blocked ? "חסום" : "לא חסום")
                    Button(state.blocked ? "בטל חסימה ב־WhatsApp" : "חסום ב־WhatsApp", role: state.blocked ? nil : .destructive) { confirmBlock = true }
                        .disabled(busy)
                    Button(state.excludeBroadcast ? "אפשר הודעות תפוצה" : "החרג מהודעות תפוצה") {
                        Task { await update(["exclude_broadcast": !state.excludeBroadcast]) }
                    }.disabled(busy)
                    Text(state.excludeBroadcast ? "הלקוח מוחרג מתפוצות." : "אפשר לבחור את הלקוח לתפוצות.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section {
                if busy { ProgressView() }
                if let error { Text(error).foregroundStyle(.secondary); Button("רענן מצב מ־WhatsApp") { Task { await load() } }.disabled(busy) }
                Text("החסימה מתבצעת בוואטסאפ של הסשן הזה. היסטוריית השיחה נשמרת. החרגה מתפוצות אינה משנה הודעות ברוכים הבאים או הודעות ידניות.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("חסימה ותפוצות")
        .task { await load() }
        .confirmationDialog(state?.blocked == true ? "לבטל חסימה?" : "לחסום את הלקוח ב־WhatsApp?", isPresented: $confirmBlock, titleVisibility: .visible) {
            Button("אישור", role: state?.blocked == true ? nil : .destructive) {
                guard let state else { return }; Task { await update(["blocked": !state.blocked]) }
            }
        }
    }
    @MainActor private func load() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { state = try await CustomerFeaturesAPI.shared.request("contact", query: identity); error = nil }
        catch { self.error = error.localizedDescription }
    }
    @MainActor private func update(_ changes: [String: Any]) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        var body = changes; body["account_id"] = conversation.accountID ?? "default"; body["jid"] = conversation.jid
        do { state = try await CustomerFeaturesAPI.shared.request("contact", method: "POST", body: body); error = nil }
        catch { self.error = error.localizedDescription }
    }
}
struct SessionNetworkView: View {
    let accountID: String
    @State private var settings: SessionNetworkSettings?
    @State private var proxy = ""
    @State private var busy = false
    @State private var error: String?
    @State private var confirmChange = false
    @State private var removeProxy = false
    var body: some View {
        Form {
            Section("החיבור של הסשן") {
                Text(SessionDirectory.shared.name(for: accountID))
                if let settings { LabeledContent("הגדרה שמורה", value: settings.address) }
                Text("Proxy עם IP יציאה שונה מאפשר חיבור נפרד לסשן. שם מכשיר אינו הופך אותו לאייפון או לגלקסי.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Proxy חדש") {
                SecureField("http / https / socks5://host:port", text: $proxy)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().privacySensitive()
                Text("אם נדרש אימות: scheme://user:password@host:port. פרטי האימות אינם מוצגים בחזרה.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("שמור וחבר מחדש") { removeProxy = false; confirmChange = true }
                    .disabled(busy || proxy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if settings?.enabled == true {
                    Button("הסר Proxy וחזור לחיבור ישיר", role: .destructive) { removeProxy = true; confirmChange = true }.disabled(busy)
                }
            }
            Section {
                if busy { ProgressView("מעדכן חיבור…") }
                if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
                Button("רענן הגדרה שמורה") { Task { await load() } }.disabled(busy)
                Text("שינוי החיבור מנתק ומחבר מחדש את הסשן. במקרה כישלון לא חוזרים אוטומטית לחיבור ישיר. הכתובת המוצגת היא הגדרת Proxy, לא אימות של IP היציאה בפועל.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("חיבור ו־IP לסשן")
        .task { await load() }
        .onDisappear { proxy = "" }
        .confirmationDialog("לשנות את החיבור של הסשן?", isPresented: $confirmChange, titleVisibility: .visible) {
            Button("שנה וחבר מחדש") { Task { await save() } }
        } message: { Text("ייתכן ניתוק קצר. השתמש בשרת Proxy שבשליטתך או שספקת את פרטיו.") }
    }
    @MainActor private func load() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { settings = try await CustomerFeaturesAPI.shared.request("network", query: [URLQueryItem(name: "account_id", value: accountID)]); error = nil }
        catch { self.error = error.localizedDescription }
    }
    @MainActor private func save() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        let value = removeProxy ? "" : proxy; proxy = ""
        do { settings = try await CustomerFeaturesAPI.shared.request("network", method: "POST", body: ["account_id": accountID, "proxy_url": value]); error = nil; await SessionDirectory.shared.refresh() }
        catch { self.error = error.localizedDescription }
    }
}

struct SessionNetworkDirectoryView: View {
    @ObservedObject private var directory = SessionDirectory.shared
    var body: some View {
        List {
            ForEach(directory.sessions.values.sorted { $0.effectiveName < $1.effectiveName }, id: \.id) { session in
                NavigationLink(session.effectiveName) { SessionNetworkView(accountID: session.id) }
            }
        }
        .navigationTitle("חיבור ו־IP לסשנים")
        .task { await directory.refresh() }
    }
}
