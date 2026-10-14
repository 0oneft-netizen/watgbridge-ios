import SwiftUI

struct CustomerAutomationSettingsView: View {
    @State private var settings = CustomerAutomationSettings()
    @State private var keyReady = false
    @State private var loaded = false
    @State private var busy = false
    @State private var error: String?
    @State private var message: String?
    @State private var testText = "שלום, אשמח לקבל פרטים"
    @State private var preview = ""
    var body: some View {
        Form {
            Section("רשימת חוסר פעילות") {
                Toggle("רשימה אוטומטית", isOn: $settings.staleEnabled)
                Picker("פרק זמן", selection: $settings.staleHours) {
                    Text("יום").tag(24); Text("שלושה ימים").tag(72); Text("שבוע").tag(168)
                    Text("שבועיים").tag(336); Text("חודש — 30 ימים").tag(720)
                    if ![24,72,168,336,720].contains(settings.staleHours) { Text("\(settings.staleHours) שעות").tag(settings.staleHours) }
                }
                TextField("מספר שעות מדויק", value: $settings.staleHours, format: .number).keyboardType(.numberPad)
                Text("הרשימה מתעדכנת בשרת מדי דקה. היא אינה שולחת הודעות בעצמה.").font(.caption).foregroundStyle(.secondary)
            }
            Section("AI ללקוח חדש") {
                Toggle("הפעל מענה ללקוח חדש", isOn: $settings.aiEnabled)
                Picker("מה לעשות עם התשובה", selection: $settings.aiMode) {
                    Text("טיוטה לאישור שלי").tag("draft")
                    Text("שליחה אוטומטית").tag("auto")
                }
                Text("מופעל אחרי הודעה חדשה נכנסת, אם אין אצלנו היסטוריית שיחה עם הלקוח בחשבון הזה. פעם אחת לכל לקוח וחשבון. אם כבר ענית, המענה האוטומטי ידולג.")
                    .font(.caption).foregroundStyle(.secondary)
                Label(keyReady ? "מפתח AI מוגדר למשתמש שלך" : "צריך להגדיר מפתח OpenAI בשרת דרך SSH", systemImage: keyReady ? "checkmark.shield" : "key")
                    .font(.footnote).foregroundStyle(.secondary)
                if !keyReady { Text("המפתח לא מוכנס לאפליקציה. מנהל השרת מפעיל את setup-ai-key.py עבור שם המשתמש שלך.").font(.caption).foregroundStyle(.secondary) }
                Text("בהפעלה, נוסח ההודעה הראשונה ופרטי העסק נשלחים ל־OpenAI לצורך ניסוח. ה־API מחויב בנפרד ממנוי ChatGPT.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("מה העסק עושה") {
                TextEditor(text: $settings.business).frame(minHeight: 160)
                Text("כתוב שירותים, שעות, כתובת ומחירים מאושרים. כשמידע חסר, ה־AI יתבקש לשאול ולא להמציא.").font(.caption).foregroundStyle(.secondary)
            }
            Section("סגנון ומגבלות") {
                TextField("סגנון התשובה", text: $settings.tone, axis: .vertical).lineLimit(2...5)
                TextField("מודל OpenAI", text: $settings.model).textInputAutocapitalization(.never).autocorrectionDisabled()
                Stepper("עד \(settings.dailyLimit) ניסוחים ביום", value: $settings.dailyLimit, in: 1...1000)
                Picker("משעה", selection: $settings.startHour) {
                    ForEach(0..<24, id: \.self) { hour in Text(String(format: "%02d:00", hour)).tag(hour) }
                }
                Picker("עד שעה", selection: $settings.endHour) {
                    ForEach(1...24, id: \.self) { hour in Text(String(format: "%02d:00", hour)).tag(hour) }
                }
                TextField("אזור זמן", text: $settings.timezone).textInputAutocapitalization(.never).autocorrectionDisabled()
                Text("הודעות מחוץ לשעות ממתינות לפתיחה עד 24 שעות. שינוי הגדרות מבטל טיוטות ואישורים ממתינים מההגדרות הקודמות.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("שמור הגדרות") { Task { await save() } }.disabled(!loaded || busy)
                Button("בדוק שוב אם המפתח הוגדר") { Task { await load(preserveEdits: true) } }.disabled(busy)
                if busy { ProgressView() }
                if let error { Text(error).foregroundStyle(.secondary) }
                if let message { Text(message).foregroundStyle(WhatsAppVisualDesign.accent) }
            }
            Section("בדיקה בלי לשלוח ללקוח") {
                TextField("הודעת לקוח לדוגמה", text: $testText, axis: .vertical).lineLimit(2...5)
                Button("שמור ובדוק ניסוח AI") { Task { await test() } }.disabled(!loaded || busy || !keyReady || settings.business.isEmpty || testText.isEmpty)
                if !preview.isEmpty { Text(preview).textSelection(.enabled) }
                Text("הבדיקה משתמשת ב־API ונספרת במכסה היומית. היא מציגה תשובה כאן בלבד.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .disabled(busy).modifier(WhatsAppListStyle()).navigationTitle("הגדרות אוטומציה")
        .task { await load() }
    }
    @MainActor private func load(preserveEdits: Bool = false) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let config: CustomerAutomationConfiguration = try await CustomerAutomationAPI.shared.request("settings"); if !preserveEdits { settings = config.settings }; keyReady = config.keyReady; loaded = true; error = nil }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
    @MainActor private func save() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let config = try await CustomerAutomationAPI.shared.save(settings); settings = config.settings; keyReady = config.keyReady; error = nil; message = "ההגדרות נשמרו" }
        catch is CancellationError {} catch { self.error = error.localizedDescription; message = nil }
    }
    @MainActor private func test() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            let config = try await CustomerAutomationAPI.shared.save(settings); settings = config.settings; keyReady = config.keyReady
            let result: AutomationPreviewReply = try await CustomerAutomationAPI.shared.request("ai-test", method: "POST", body: ["text": testText])
            preview = result.reply; error = nil; message = "בדיקה הושלמה — לא נשלח ללקוח"
        } catch is CancellationError {} catch { self.error = error.localizedDescription; message = nil }
    }
}
struct CustomerAutomationAIInbox: View {
    @State private var jobs: [AutomationAIReply] = []
    @State private var editing: AutomationAIReply?
    @State private var busy = false
    @State private var error: String?
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        List {
            Section {
                NavigationLink("הגדרות המענה האוטומטי") { CustomerAutomationSettingsView() }
                Text("מוצגות עד 200 הפניות האחרונות. שיחה שכבר קיימת אצלנו לא נחשבת לקוח חדש.").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(jobs) { job in
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(SessionDirectory.shared.name(for: job.accountID)).font(.caption.weight(.semibold)).foregroundStyle(WhatsAppVisualDesign.accent)
                        Text(job.name == job.jid ? (job.jid.hasSuffix("@s.whatsapp.net") ? String(job.jid.split(separator: "@").first ?? "") : "איש קשר") : job.name).font(.headline)
                        Text(job.inputText).lineLimit(4)
                        Text(automationAIState(job.state)).font(.caption).foregroundStyle(.secondary)
                        if !job.reply.isEmpty { Text(job.reply).textSelection(.enabled) }
                        if !job.lastError.isEmpty { Text(job.lastError).font(.caption).foregroundStyle(.secondary) }
                    }
                    if job.state == "draft" {
                        Button("ערוך ואשר שליחה") { editing = job }.disabled(busy)
                        Button("בטל תשובה זו", role: .destructive) { Task { await action(job.id, "cancel") } }.disabled(busy)
                    }
                    if job.state == "failed" { Button("נסה ניסוח מחדש") { Task { await action(job.id, "retry") } }.disabled(busy) }
                }
            }
            if jobs.isEmpty { Text("פניות חדשות יופיעו אחרי הפעלת ה־AI וקבלת הודעה מלקוח חדש.").foregroundStyle(.secondary) }
            if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
        }.modifier(WhatsAppListStyle()).navigationTitle("תשובות AI")
        .sheet(item: $editing) { job in AutomationAIEditor(job: job) }
        .refreshable { await load() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled { await load(); do { try await Task.sleep(for: .seconds(8)) } catch { return } }
        }
    }
    @MainActor private func load() async {
        do { jobs = try await CustomerAutomationAPI.shared.request("ai-jobs"); error = nil }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
    @MainActor private func action(_ id: Int64, _ action: String) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let _: FeatureAccepted = try await CustomerAutomationAPI.shared.request("ai-action", method: "POST", body: ["id": id, "action": action, "reply": ""]); await load() }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
private func automationAIState(_ state: String) -> String {
    switch state {
    case "generating": return "AI מנסח תשובה"
    case "approved": return "אושרה וממתינה לשליחה"
    case "draft": return "טיוטה לבדיקה"
    case "failed": return "ניסוח AI נכשל — לא נשלח"
    default: return broadcastStatus(state)
    }
}
private struct AutomationAIEditor: View {
    let job: AutomationAIReply
    @State private var reply: String
    @State private var busy = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss
    init(job: AutomationAIReply) { self.job = job; _reply = State(initialValue: job.reply) }
    var body: some View {
        NavigationStack {
            Form {
                Section("הודעת הלקוח") { Text(job.inputText) }
                Section("התשובה שלך") { TextEditor(text: $reply).frame(minHeight: 180) }
                Section {
                    Button("אשר והכנס לתור השליחה") { Task { await approve() } }.disabled(busy || reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if busy { ProgressView() }
                    if let error { Text(error).foregroundStyle(.secondary) }
                }
            }.disabled(busy).navigationTitle("אישור תשובת AI")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("סגור") { dismiss() }.disabled(busy) } }
        }
    }
    @MainActor private func approve() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let _: FeatureAccepted = try await CustomerAutomationAPI.shared.request("ai-action", method: "POST", body: ["id": job.id, "action": "approve", "reply": reply]); dismiss() }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
