import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor struct LocalAgentCenter: View {
    var body: some View {
        List {
            Section {
                Label("ה־AI שלי", systemImage: "sparkles").font(.title2.bold())
                Text("מנוע מקומי בשרת שלך · ללא מפתח חיצוני. אתה מנהל את ההוראות, הידע והדוגמאות.")
                Text("המודל הנוכחי קטן: הוא עשוי לטעות והתשובות יכולות לקחת עשרות שניות. שליחה ללקוחות מחייבת אישור שלך.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("למד אותו בעצמך") {
                NavigationLink("הוראות, קטלוג ודוגמאות") { LocalAgentSettingsView() }
                NavigationLink("חדר אימון ושיחה לדוגמה") { LocalAgentPlayground() }
                NavigationLink("גרסאות הגדרות קודמות") { LocalAgentVersionsView() }
            }
            Section("לקוחות") {
                NavigationLink("טיוטות לאישור שלי") { LocalAgentInbox() }
                NavigationLink("צ׳אטים שהשהיתי") { LocalAgentPausedView() }
                Text("הפעלת טיוטות יוצרת הצעות להודעות טקסט חדשות בצ׳אטים פרטיים. אין שליחה אוטומטית. נשמר זיכרון שיחה במסד הנתונים, והמנוע מקבל קטע קצר מההודעות האחרונות וקטעי ידע נבחרים.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("ה־AI שלי")
    }
}

@MainActor struct LocalAgentSettingsView: View {
    @State private var config = LocalAgentConfig()
    @State private var workspace = UserWorkspace.id
    @State private var ready = false
    @State private var busy = false
    @State private var feedback: String?
    @State private var importing = false
    @State private var importText = ""
    var body: some View {
        Form {
            Section("שליטה") {
                Toggle("צור טיוטות מהודעות חדשות", isOn: $config.enabled)
                Text("נדרשת שמירה. לא נשלחות הודעות אוטומטית, ולא מטופלות הודעות שהתקבלו לפני ההפעלה.").font(.caption)
            }
            editor("הוראות לנציג", text: $config.instructions, limit: 1000,
                   hint: "הגדר תפקיד, שפה, סגנון, דרך מכירה ודברים שאסור להבטיח. ההוראות אינן מאמנות מחדש את המודל.")
            editor("ידע עסקי וקטלוג", text: $config.knowledge, limit: 50000,
                   hint: "כתוב כל מוצר או כלל בשורה נפרדת, עם שם, מחיר ופרטים מאושרים. בכל תשובה נבחרים קטעים רלוונטיים; לא כל המאגר נכנס למודל יחד.")
            editor("דוגמאות ותיקונים", text: $config.examples, limit: 10000,
                   hint: "למשל: לקוח שואל… / תשובה רצויה… . אחרי תיקון בחדר האימון, שמור אותו כאן.")
            Section {
                Button("שמור את ה־AI שלי") { Task { await save() } }.disabled(!ready || busy || tooLong)
                if busy { ProgressView() }
                if let feedback { Text(feedback).font(.footnote).foregroundStyle(.secondary) }
            }
            Section("גיבוי אישי של ההגדרות") {
                Button("העתק גיבוי JSON") {
                    guard let data = try? JSONEncoder().encode(config) else { return }
                    UIPasteboard.general.string = String(data: data, encoding: .utf8)
                }.disabled(!ready)
                Button("ייבא גיבוי לבדיקה לפני שמירה") { importing = true }
                Text("גיבוי ההגדרות מכיל את תוכן העסק. הייבוא לא מפעיל טיוטות בלי שמירה מפורשת.").font(.caption)
            }
        }
        .navigationTitle("הנדסת הנציג שלי")
        .disabled(busy || UserWorkspace.id != workspace)
        .task { await load() }
        .sheet(isPresented: $importing) {
            NavigationStack {
                Form {
                    TextEditor(text: $importText).frame(minHeight: 240)
                    Button("טען לטופס, ללא הפעלה") {
                        do {
                            let value = try JSONDecoder().decode(LocalAgentConfig.self, from: Data(importText.utf8))
                            config.instructions = value.instructions; config.knowledge = value.knowledge
                            config.examples = value.examples; config.enabled = false; importing = false
                        } catch { feedback = "קובץ הגדרות לא תקין"; importing = false }
                    }
                }.navigationTitle("הדבק גיבוי JSON")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("ביטול") { importing = false } } }
            }
        }
    }
    private var tooLong: Bool { config.instructions.count > 1000 || config.knowledge.count > 50000 || config.examples.count > 10000 }
    private func editor(_ title: String, text: Binding<String>, limit: Int, hint: String) -> some View {
        Section(title) {
            TextEditor(text: text).frame(minHeight: title == "הוראות לנציג" ? 130 : 200)
            Text("\(text.wrappedValue.count)/\(limit) תווים · \(hint)").font(.caption).foregroundStyle(.secondary)
        }
    }
    private func load() async {
        do { config = try await LocalAgentAPI.request("config", workspace: workspace); ready = true }
        catch { feedback = error.localizedDescription }
    }
    private func save() async {
        busy = true; defer { busy = false }
        do { config = try await LocalAgentAPI.request("config", workspace: workspace, method: "PUT", body: JSONEncoder().encode(config)); feedback = "נשמר. טיוטות ישנות בוטלו כדי שלא ישתמשו בהוראות הקודמות." }
        catch { feedback = error.localizedDescription }
    }
}

@MainActor struct LocalAgentPlayground: View {
    @State private var workspace = UserWorkspace.id
    @State private var turns: [LocalAgentTurn] = []
    @State private var text = ""
    @State private var busy = false
    @State private var feedback: String?
    @State private var excerpt = ""
    var body: some View {
        Form {
            Section {
                Text("בדיקה לפי ההגדרות ששמרת. לא נשלח דבר ללקוח. השיחה כאן נשמרת רק כל עוד המסך פתוח.").font(.footnote)
                NavigationLink("ערוך הוראות וידע") { LocalAgentSettingsView() }
            }
            Section("שיחת אימון") {
                ForEach(Array(turns.enumerated()), id: \.offset) { _, turn in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(turn.role == "user" ? "לקוח לדוגמה" : "הנציג שלי").font(.caption.bold())
                        Text(turn.content).textSelection(.enabled)
                        if turn.role == "assistant" {
                            Button("העתק תשובה לצורך תיקון בדוגמאות") { UIPasteboard.general.string = turn.content }.font(.caption)
                        }
                    }
                }
                TextField("כתוב כלקוח…", text: $text, axis: .vertical).lineLimit(2...6)
                Button("בדוק תשובה") { Task { await test() } }.disabled(busy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > 1000)
                Button("אפס שיחת אימון") { turns = []; excerpt = "" }.disabled(busy)
                if busy { ProgressView("המנוע המקומי מנסח…") }
                if let feedback { Text(feedback).font(.footnote).foregroundStyle(.secondary) }
            }
            if !excerpt.isEmpty { Section("קטעי הידע שנבחרו לתשובה האחרונה") { Text(excerpt).font(.caption).textSelection(.enabled) } }
        }.navigationTitle("חדר אימון").disabled(UserWorkspace.id != workspace)
    }
    private func test() async {
        busy = true; defer { busy = false }
        let candidate = Array(turns.suffix(6)) + [LocalAgentTurn(role: "user", content: text)]
        do {
            let body = try LocalAgentAPI.json(["turns": candidate.map { ["role": $0.role, "content": $0.content] }])
            let result: LocalAgentTest = try await LocalAgentAPI.request("test", workspace: workspace, method: "POST", body: body)
            turns = candidate + [LocalAgentTurn(role: "assistant", content: result.reply)]
            text = ""; excerpt = result.contextExcerpt; feedback = String(format: "הניסוח לקח %.1f שניות. בדוק ותקן לפני שימוש.", result.seconds)
        } catch { feedback = error.localizedDescription }
    }
}

@MainActor struct LocalAgentInbox: View {
    @State private var workspace = UserWorkspace.id
    @State private var jobs: [LocalAgentJob] = []
    @State private var selected: LocalAgentJob?
    @State private var feedback: String?
    var body: some View {
        List {
            Section {
                Text("רק לחיצה מפורשת על אישור ושליחה שולחת ללקוח. הודעה חדשה או תשובה שכבר נשלחה מבטלות טיוטה שהתיישנה.").font(.caption)
                Button("רענן") { Task { await load() } }
            }
            ForEach(jobs) { job in
                Button { selected = job } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(ChatIdentity.customerPhone(from: job.jid))
                        Text(SessionDirectory.shared.name(for: job.accountID)).font(.caption)
                        Text(job.inputText).lineLimit(2)
                        Text(job.stateLabel).font(.caption).foregroundStyle(.secondary)
                        if !job.lastError.isEmpty { Text(job.lastError).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            if jobs.isEmpty { Text("אין טיוטות. הפעל יצירת טיוטות בהגדרות ואז המתן להודעת טקסט חדשה.") }
            if let feedback { Text(feedback).font(.footnote) }
        }.navigationTitle("טיוטות ה־AI שלי").refreshable { await load() }.task { await load() }
        .sheet(item: $selected, onDismiss: { Task { await load() } }) { LocalAgentDraftView(job: $0) }
    }
    private func load() async {
        do { jobs = try await LocalAgentAPI.request("jobs", workspace: workspace) }
        catch { feedback = error.localizedDescription }
    }
}

@MainActor private struct LocalAgentDraftView: View {
    let job: LocalAgentJob
    @State private var workspace = UserWorkspace.id
    @State private var reply: String
    @State private var busy = false
    @State private var feedback: String?
    @State private var confirmSend = false
    @Environment(\.dismiss) private var dismiss
    init(job: LocalAgentJob) { self.job = job; _reply = State(initialValue: job.reply) }
    var body: some View {
        NavigationStack {
            Form {
                Section("נתיב שליחה") {
                    Text(SessionDirectory.shared.name(for: job.accountID))
                    Text(ChatIdentity.customerPhone(from: job.jid)).textSelection(.enabled)
                    Text(job.inputText)
                }
                Section("בדוק וערוך לפני שליחה") { TextEditor(text: $reply).frame(minHeight: 180) }
                Section {
                    Button("אישור ושליחה ללקוח") { confirmSend = true }.disabled(job.state != "draft" || reply.isEmpty)
                    if job.state == "failed" { Button("נסה לנסח שוב") { Task { await action("retry") } } }
                    Button("בטל טיוטה") { Task { await action("cancel") } }
                    Button("השהה AI בצ׳אט הזה") { Task { await action("pause") } }
                    if let feedback { Text(feedback).foregroundStyle(.secondary) }
                }
            }.disabled(busy || UserWorkspace.id != workspace)
            .navigationTitle("בדיקת תשובה")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("סגירה") { dismiss() }.disabled(busy) } }
            .confirmationDialog("לשלוח את הנוסח הערוך מהמספר המוצג ללקוח?", isPresented: $confirmSend) {
                Button("שלח עכשיו") { Task { await action("send") } }
                Button("ביטול", role: .cancel) {}
            }
        }
    }
    private func action(_ value: String) async {
        busy = true; defer { busy = false }
        do { let _: LocalAgentOK = try await LocalAgentAPI.request("action", workspace: workspace, method: "POST", body: LocalAgentAPI.json(["id": job.id, "action": value, "reply": reply])); dismiss() }
        catch { feedback = error.localizedDescription }
    }
}

@MainActor struct LocalAgentPausedView: View {
    @State private var workspace = UserWorkspace.id
    @State private var chats: [LocalAgentPausedChat] = []
    @State private var feedback: String?
    var body: some View {
        List {
            ForEach(chats) { chat in
                VStack(alignment: .leading) {
                    Text(chat.jid); Text(SessionDirectory.shared.name(for: chat.accountID)).font(.caption)
                    Button("אפשר טיוטות להודעות חדשות") { Task { await resume(chat) } }
                }
            }
            if chats.isEmpty { Text("אין צ׳אטים שהושהו") }
            if let feedback { Text(feedback) }
        }.navigationTitle("צ׳אטים שהשהיתי").task { await load() }
    }
    private func load() async { do { chats = try await LocalAgentAPI.request("chats", workspace: workspace) } catch { feedback = error.localizedDescription } }
    private func resume(_ chat: LocalAgentPausedChat) async {
        do { let _: LocalAgentOK = try await LocalAgentAPI.request("chats", workspace: workspace, method: "PUT", body: LocalAgentAPI.json(["account_id": chat.accountID, "jid": chat.jid, "paused": false])); await load() }
        catch { feedback = error.localizedDescription }
    }
}

@MainActor struct LocalAgentVersionsView: View {
    @State private var workspace = UserWorkspace.id
    @State private var versions: [LocalAgentVersion] = []
    @State private var feedback: String?
    var body: some View {
        List {
            Text("עשר שמירות קודמות. שחזור מחזיר את הידע והדוגמאות ומכבה יצירת טיוטות עד להפעלה מחדש.").font(.footnote)
            ForEach(versions) { version in
                VStack(alignment: .leading) {
                    Text(Date(timeIntervalSince1970: Double(version.createdAt)), style: .date)
                    Text(version.config.instructions).lineLimit(2)
                    Button("שחזר גרסה זו וכבה יצירת טיוטות") { Task { await restore(version) } }
                }
            }
            if let feedback { Text(feedback) }
        }.navigationTitle("גרסאות ההגדרות").task { await load() }
    }
    private func load() async { do { versions = try await LocalAgentAPI.request("versions", workspace: workspace) } catch { feedback = error.localizedDescription } }
    private func restore(_ version: LocalAgentVersion) async {
        do {
            let current: LocalAgentConfig = try await LocalAgentAPI.request("config", workspace: workspace)
            var config = version.config; config.revision = current.revision; config.enabled = false
            let _: LocalAgentConfig = try await LocalAgentAPI.request("config", workspace: workspace, method: "PUT", body: JSONEncoder().encode(config))
            feedback = "שוחזר. יצירת טיוטות כבויה."; await load()
        } catch { feedback = error.localizedDescription }
    }
}
