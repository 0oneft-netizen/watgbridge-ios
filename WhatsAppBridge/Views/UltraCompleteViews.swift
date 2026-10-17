import SwiftUI

@MainActor struct UltraChatPreferenceView: View {
    let conversation: Conversation
    var onAutoChange: ((Bool) -> Void)? = nil
    @State private var preference: UltraChatPreferences?
    @State private var until = Date().addingTimeInterval(3600)
    @State private var busy = false
    @State private var message: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        Form {
            if preference != nil {
                Section("שפת הלקוח") {
                    Picker("שפה לתשובות שלך", selection: Binding(get: { preference?.language ?? "" }, set: { preference?.language = $0; preference?.manual = !$0.isEmpty })) {
                        Text("זיהוי אוטומטי").tag("")
                        ForEach(UltraSuiteAPI.languages, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Toggle("תרגם הודעות נכנסות לעברית", isOn: Binding(get: { preference?.autoTranslate ?? false }, set: { preference?.autoTranslate = $0 }))
                    Text("זיהוי השפה מתבצע באייפון. הודעות שרובן בעברית אינן נשלחות לתרגום לעברית. בבחירת שפה ידנית היא נשמרת גם אם זיהוי אוטומטי מציע שפה אחרת.").font(.caption).foregroundStyle(.secondary)
                    Button("שמור שפה ותרגום") { Task { await save(mute: false) } }
                }
                Section("השתקה לזמן מוגדר") {
                    if let p = preference {
                        Text(p.muteUntil == -1 ? "השתקה ללא הגבלת זמן" : p.muteUntil > Int64(Date().timeIntervalSince1970) ? "מושתק עד \(Date(timeIntervalSince1970: Double(p.muteUntil)).formatted())" : "אין השתקה מתוזמנת")
                    }
                    Button("השתק לשעה") { setMute(Date().addingTimeInterval(3600)) }
                    Button("השתק ל־8 שעות") { setMute(Date().addingTimeInterval(8 * 3600)) }
                    Button("השתק עד 08:00 בבוקר") {
                        setMute(Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 8, minute: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(8 * 3600))
                    }
                    DatePicker("עד מתי", selection: $until, in: Date()...Date().addingTimeInterval(365 * 86400), displayedComponents: [.date, .hourAndMinute])
                    Button("השתק עד הזמן שבחרתי") { setMute(until) }
                    Button("השתק ללא הגבלת זמן") { preference?.muteUntil = -1; Task { await save(mute: true) } }
                    Button("בטל השתקה") { preference?.muteUntil = 0; Task { await save(mute: true) } }
                    Text("ההשתקה נשמרת בשרת וחלה על הודעות הצ׳אט דרך WA Alerts ו־APNs. היא אינה משתיקה את WhatsApp המקורי או התראות ניתוק סשן.").font(.caption).foregroundStyle(.secondary)
                }
                Section { NavigationLink { UltraCustomerMatchesView(conversation: conversation) } label: { Label("מצא את הלקוח בכל החשבונות", systemImage: "person.crop.circle.badge.magnifyingglass") } }
                Section { NavigationLink { UltraGlobalExclusionView(conversation: conversation) } label: { Label("החרגה קבועה מתפוצות בכל החשבונות", systemImage: "person.crop.circle.badge.minus") } }
            }
            if busy { ProgressView() }
            if let message { Text(message).foregroundStyle(.secondary) }
        }.disabled(busy).navigationTitle("שפה, השתקה ולקוח")
        .task { do { preference = try await UltraPreferenceStore.shared.load(conversation) } catch { message = "לא ניתן לטעון הגדרות צ׳אט." } }
    }
    private func setMute(_ date: Date) { preference?.muteUntil = Int64(date.timeIntervalSince1970); Task { await save(mute: true) } }
    private func save(mute: Bool) async {
        guard !busy, scope == UserWorkspace.id, var p = preference else { return }; busy = true; defer { busy = false }
        p.change = mute ? "mute" : "translation"; p.resetLegacyMute = mute
        do { try await UltraPreferenceStore.shared.save(p, chat: conversation); preference = UltraPreferenceStore.shared.values[conversation.id]; onAutoChange?(preference?.autoTranslate ?? false); message = "נשמר" }
        catch { message = "השמירה לא הושלמה. אפשר לנסות שוב." }
    }
}

@MainActor struct UltraGlobalExclusionView: View {
    let conversation: Conversation
    @State private var value: UltraExclusion?
    @State private var busy = false
    @State private var error: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        Form {
            if let value {
                Text(value.phone.isEmpty ? "מספר הלקוח אינו מזוהה" : value.phone)
                Text(value.excluded ? "הלקוח מוחרג מכל תפוצות המשתמש שלך" : "אין החרגה לפי מספר הלקוח")
                Button(value.excluded ? "בטל החרגה לפי מספר" : "החרג מכל התפוצות שלי", role: value.excluded ? nil : .destructive) { Task { await load(change: !value.excluded) } }.disabled(busy || value.phone.isEmpty)
            }
            Text("ההחרגה נבדקת גם ברשימות חדשות וגם לפני שליחה מרשימות קיימות. היא חלה כשמספרו האמיתי של הלקוח מזוהה. החרגה שכבר נשמרה עבור חשבון יחיד נשארת בתוקף בנפרד.").font(.footnote).foregroundStyle(.secondary)
            if busy { ProgressView() }
            if let error { Text(error) }
        }.navigationTitle("אל תכלול בתפוצות").task { await load() }
    }
    private func load(change: Bool? = nil) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            var body: [String: Any]? = nil
            if let change { body = ["account_id": conversation.accountID ?? "default", "jid": conversation.jid, "excluded": change] }
            value = try await UltraCompleteAPI.request("features/global-exclusion", workspace: scope, method: change == nil ? "GET" : "POST", query: [.init(name: "account_id", value: conversation.accountID ?? "default"), .init(name: "jid", value: conversation.jid)], body: body)
            error = nil
        } catch { self.error = "הפעולה לא הושלמה. ודא שמספר הלקוח מזוהה." }
    }
}

@MainActor struct UltraCustomerMatchesView: View {
    var conversation: Conversation? = nil
    @State private var phone = ""
    @State private var results: [UltraCustomerMatch] = []
    @State private var busy = false
    @State private var message: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        List {
            Section {
                TextField("מספר מלא עם קידומת מדינה", text: $phone).keyboardType(.phonePad)
                Button("חפש בכל המספרים שלי") { Task { await search() } }.disabled(busy)
                Text("החיפוש משווה מספר מלא. הוא לא מאחד או מעביר שיחות בין החשבונות.").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(results) { hit in
                NavigationLink { ChatView(conversation: hit.conversation) } label: {
                    VStack(alignment: .leading) { Text(hit.name); Text(hit.accountName + " · " + hit.phone).font(.caption).foregroundStyle(.secondary) }
                }
            }
            if busy { ProgressView() }
            if let message { Text(message).foregroundStyle(.secondary) }
        }.navigationTitle("הלקוח בכל החשבונות")
        .task { if let conversation { phone = ChatIdentity.customerPhone(conversation: conversation); await search() } }
    }
    private func search() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { results = try await UltraCompleteAPI.request("features/customer-matches", workspace: scope, query: [.init(name: "phone", value: phone)]); message = results.isEmpty ? "לא נמצאו שיחות עם המספר הזה." : nil }
        catch { message = "החיפוש לא הושלם. הזן מספר מלא עם קידומת מדינה." }
    }
}

@MainActor struct UltraLoginDevicesView: View {
    @State private var deviceLabel = UltraCompleteAPI.deviceLabel
    @State private var devices: [UltraLoginDevice] = []
    @State private var pending: UltraLoginDevice?
    @State private var busy = false
    @State private var error: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        List {
            Section("שם האייפון הזה ברשימת הכניסות") {
                TextField("למשל: האייפון שלי / עבודה", text: $deviceLabel)
                Button("שמור שם ורענן") {
                    let value = String(deviceLabel.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
                    guard !value.isEmpty else { return }
                    UserDefaults.standard.set(value, forKey: "ultra.device.label")
                    Task { await load() }
                }.disabled(busy)
            }
            Section { Text("אלה כניסות למשתמש ULTRA-SAP, כולל דפדפן WA Alerts. שם המכשיר הוא תיאור שמסר הלקוח, ולא זיהוי חומרה מאומת.").font(.caption).foregroundStyle(.secondary) }
            ForEach(devices) { device in
                VStack(alignment: .leading, spacing: 6) {
                    Text(device.label).font(.headline)
                    if device.current { Text("המכשיר הנוכחי").font(.caption).foregroundStyle(.green) }
                    Text("אימות אחרון: \(Date(timeIntervalSince1970: Double(device.lastSeen)).formatted())").font(.caption)
                    if !device.current && device.revocable { Button("נתק כניסה זו", role: .destructive) { pending = device }.disabled(busy) }
                }
            }
            Button("רענן") { Task { await load() } }.disabled(busy)
            if busy { ProgressView() }
            if let error { Text(error).foregroundStyle(.secondary) }
        }.navigationTitle("מכשירים מחוברים").task { await load() }
        .confirmationDialog("לנתק את הכניסה שנבחרה?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), titleVisibility: .visible) {
            Button("נתק", role: .destructive) { guard let device = pending else { return }; pending = nil; Task { await revoke(device) } }
        } message: { Text("אם זו כניסת WA Alerts, ההתראות שלה ייפסקו עד התחברות מחדש.") }
    }
    private func load() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { devices = try await UltraCompleteAPI.request("auth/devices", workspace: scope); error = nil } catch { self.error = "לא ניתן לטעון את הכניסות." }
    }
    private func revoke(_ device: UltraLoginDevice) async {
        guard !busy, !device.current else { return }; busy = true
        do { let _: FeatureAccepted = try await UltraCompleteAPI.request("auth/devices/revoke", workspace: scope, method: "POST", body: ["id": device.id]); busy = false; await load() }
        catch { busy = false; error = "ביטול הכניסה לא אושר. רענן ובדוק שוב." }
    }
}

@MainActor struct UltraSessionAlertsView: View {
    @State private var alerts: [UltraSessionAlert] = []
    @State private var error: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        List {
            Section { Text("ניתוק של סשן שהיה מחובר נשמר כאן, ונשלחת התראה בערוצי ההתראות שכבר מוגדרים למשתמש. מצב החיבור נרשם כפי שנמסר; סיבה מפורטת לא תמיד זמינה.").font(.caption) }
            ForEach(alerts) { alert in
                VStack(alignment: .leading, spacing: 5) { Text(alert.name).font(.headline); Text(label(alert.reason)); Text(Date(timeIntervalSince1970: Double(alert.createdAt)).formatted()).font(.caption).foregroundStyle(.secondary) }
            }
            if let error { Text(error) }
        }.navigationTitle("התראות סשנים")
        .task { while !Task.isCancelled { do { alerts = try await UltraCompleteAPI.request("features/session-alerts", workspace: scope); error = nil } catch { if !Task.isCancelled { self.error = "לא ניתן לרענן התראות." } }; do { try await Task.sleep(nanoseconds: 15_000_000_000) } catch { return } } }
    }
    private func label(_ reason: String) -> String { switch reason { case "disconnected": return "החיבור נותק"; case "reconnect_required": return "נדרש חיבור מחדש"; case "logged_out": return "החשבון התנתק מ־WhatsApp"; default: return reason } }
}

@MainActor struct UltraSettingsBackupView: View {
    @State private var scope = UserWorkspace.id
    @State private var busy = false
    @State private var message: String?
    @State private var confirmRestore = false
    private struct BackupResponse: Decodable { let payload: [String: BackupValue]; let updatedAt: Int64
        enum CodingKeys: String, CodingKey { case payload, updatedAt = "updated_at" }
    }
    private enum BackupValue: Decodable {
        case string(String), bool(Bool), number(Double)
        init(from decoder: Decoder) throws { let v = try decoder.singleValueContainer(); if let b = try? v.decode(Bool.self) { self = .bool(b) } else if let s = try? v.decode(String.self) { self = .string(s) } else { self = .number(try v.decode(Double.self)) } }
        var value: Any { switch self { case .string(let s): return s; case .bool(let b): return b; case .number(let n): return n } }
    }
    var body: some View {
        Form {
            Text("גיבוי אישי בשרת: שפות צ׳אטים, חתימה עסקית, אפקט הקול והעדפות התראות ומדיה. אפשר לשחזר אחרי כניסה לאותו משתמש באייפון אחר.")
            Text("סיסמאות, קוד נעילה, אסימוני כניסה, מפתחות OpenAI, הודעות וקבצי מדיה אינם נכללים בגיבוי ההגדרות.").font(.caption).foregroundStyle(.secondary)
            Button("גבה את ההגדרות שלי עכשיו") { Task { await backup() } }.disabled(busy)
            Button("שחזר את הגיבוי שלי") { confirmRestore = true }.disabled(busy)
            if busy { ProgressView() }
            if let message { Text(message).foregroundStyle(.secondary) }
        }.navigationTitle("גיבוי הגדרות אישי")
        .confirmationDialog("לשחזר הגדרות מהגיבוי?", isPresented: $confirmRestore, titleVisibility: .visible) { Button("שחזר") { Task { await restore() } } } message: { Text("הערכים שנמצאים בגיבוי יחליפו את ההעדפות המקומיות המתאימות.") }
    }
    private func backup() async {
        guard !busy, UserWorkspace.id == scope else { return }; busy = true; defer { busy = false }
        do { let response: BackupResponse = try await UltraCompleteAPI.request("features/settings-backup", workspace: scope, method: "POST", body: ["payload": UltraSettingsBackupPolicy.snapshot(UserWorkspace.defaults)]); message = "הגיבוי נשמר: \(Date(timeIntervalSince1970: Double(response.updatedAt)).formatted())" }
        catch { message = "הגיבוי לא הושלם." }
    }
    private func restore() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            let response: BackupResponse = try await UltraCompleteAPI.request("features/settings-backup", workspace: scope, method: "POST", body: ["restore": true])
            guard UserWorkspace.id == scope else { return }
            guard response.updatedAt > 0 else { message = "עדיין אין גיבוי למשתמש הזה."; return }
            for (key, value) in response.payload where UltraSettingsBackupPolicy.allows(key) { UserWorkspace.defaults.set(value.value, forKey: key) }
            UserLocalStores.reload(); message = "ההגדרות שוחזרו. פתח מחדש את המסכים כדי לראות את ההעדפות המעודכנות."
        } catch { message = "השחזור לא הושלם." }
    }
}

@MainActor struct UltraVoiceTranscriptView: View {
    let message: Message
    @State private var result: UltraTranscript?
    @State private var busy = false
    @State private var error: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        NavigationStack {
            Form {
                Text("בלחיצה על תמלול, ההקלטה תישלח ל־OpenAI באמצעות המפתח של המשתמש שלך. התמלול והתרגום כפופים למכסה ולחיוב שימוש. תמלול עלול להכיל טעויות.").font(.caption)
                Button(busy ? "מתמלל…" : "תמלל ותרגם לעברית") { Task { await transcribe() } }.disabled(busy)
                if busy { ProgressView() }
                if let result {
                    Section("תמלול המקור") { Text(result.text).textSelection(.enabled) }
                    Section("עברית") { Text(result.translationAvailable ? result.hebrew : "התרגום לא הושלם. התמלול זמין למעלה; אפשר לנסות שוב.").textSelection(.enabled) }
                }
                if let error { Text(error).foregroundStyle(.secondary) }
            }.navigationTitle("תמלול הקלטה")
        }
    }
    private func transcribe() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { result = try await UltraCompleteAPI.request("features/transcribe-voice", workspace: scope, method: "POST", body: ["account_id": message.accountID ?? "default", "jid": message.chatJID, "message_id": message.messageID], timeout: 120); error = nil }
        catch { self.error = "התמלול לא הושלם. נדרש מפתח OpenAI פעיל וקובץ שמע בשרת עד 24 MiB." }
    }
}

struct UltraRecipientReviewSection: View {
    let rows: [UltraRecipientCheck]
    var body: some View {
        Section("בדיקת נמענים לפני יצירת תפוצה") {
            Text("\(rows.filter(\.eligible).count) נמענים אחרי הסרת כפילויות והחרגות")
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 3) {
                    Text(row.phone.isEmpty ? row.jid : row.phone)
                    Text("יישלח מתוך: " + row.accountName).font(.caption)
                    if let phone = row.accountPhone, !phone.isEmpty { Text(phone).font(.caption).monospacedDigit() }
                    if row.excluded { Text("מוחרג — לא יישלח").foregroundStyle(.orange) }
                    else if !row.duplicateOf.isEmpty { Text("אותו מספר כבר נבחר בחשבון אחר — יוסר").foregroundStyle(.orange) }
                    else if row.unknownPhone { Text("מספר לא מזוהה: לא ניתן לוודא כפילות בין חשבונות").foregroundStyle(.orange) }
                }.font(.subheadline)
            }
        }
    }
}
