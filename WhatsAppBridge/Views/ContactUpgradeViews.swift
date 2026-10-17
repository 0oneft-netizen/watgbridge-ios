import SwiftUI

struct MessageReceiptInfoView: View {
    let message: Message
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var info: ContactMessageInfo?
    @State private var busy = false
    @State private var errorText: String?
    @State private var workspace = UserWorkspace.id

    var body: some View {
        NavigationStack {
            Form {
                Section("ההודעה") {
                    LabeledContent("המספר שלך", value: SessionDirectory.shared.name(for: message.accountID))
                    if !message.text.isEmpty { Text(message.text).lineLimit(5).textSelection(.enabled) }
                    if let info {
                        timeRow("זמן ההודעה", timestamp: info.createdAt, icon: "clock")
                    }
                }
                if let info, info.fromMe {
                    Section("אישורים") {
                        timeRow("השליחה אושרה בשרת", timestamp: info.sentConfirmedAt, icon: "checkmark")
                        timeRow(info.isGroup ? "אישור מסירה ראשון" : "נמסרה", timestamp: info.deliveredAt, icon: "checkmark.circle")
                        timeRow(info.isGroup ? "אישור קריאה ראשון" : "נקראה", timestamp: info.readAt, icon: "checkmark.circle.fill")
                    }
                    Section {
                        Text("שעת אישור השליחה היא השעה שבה השרת שלנו קיבל תשובה מוצלחת לשליחה. מסירה וקריאה מוצגות רק לפי אישורים שהתקבלו מ־WhatsApp מאז התקנת העדכון. כאשר אין שעה מאומתת, מוצג ׳לא זמין׳.")
                        if info.isGroup { Text("בשיחה קבוצתית השעות מתייחסות לאישור הראשון שנשמר, ולא לאישור מכל חברי הקבוצה.") }
                        Text("השעות מוצגות לפי אזור הזמן של האייפון. אישורי קריאה עשויים לא להיות זמינים בהתאם להגדרות הפרטיות של הלקוח.")
                    }.font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    if busy { ProgressView("בודק אישורים…") }
                    if let errorText { Text(errorText).foregroundStyle(.secondary) }
                    Button("רענן") { Task { await refresh() } }.disabled(busy)
                }
            }
            .navigationTitle("פרטי הודעה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("סיום") { dismiss() } } }
            .privacySensitive()
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    await refresh()
                    do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
                }
            }
        }
    }
    private func timeRow(_ title: String, timestamp: Int64?, icon: String) -> some View {
        HStack(alignment: .top) {
            Label(title, systemImage: icon)
            Spacer()
            if let date = ContactMessageInfo.date(timestamp) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(date, format: .dateTime.day().month().year())
                    Text(date, format: .dateTime.hour().minute().second()).monospacedDigit()
                }.textSelection(.enabled)
            } else { Text("לא זמין").foregroundStyle(.secondary) }
        }.font(.subheadline)
    }
    @MainActor private func refresh() async {
        guard !busy, !Task.isCancelled, UserWorkspace.id == workspace else { return }
        busy = true; defer { busy = false }
        do { info = try await ContactUpgradeAPI.info(message, workspace: workspace); errorText = nil }
        catch is CancellationError { }
        catch { if !Task.isCancelled { errorText = "לא ניתן לטעון פרטי הודעה. אפשר לרענן שוב." } }
    }
}

@MainActor
struct ContactBlockAccountsView: View {
    let conversation: Conversation
    @State private var plan: ContactBlockPlan?
    @State private var selected = Set<String>()
    @State private var results: [String: String] = [:]
    @State private var confirmed = Set<String>()
    @State private var failed = Set<String>()
    @State private var busy = false
    @State private var errorText: String?
    @State private var desired = true
    @State private var confirm = false
    @State private var operation: Task<Void, Never>?
    @State private var workspace = UserWorkspace.id
    private var currentAccount: String { conversation.accountID ?? "default" }
    var body: some View {
        Form {
            Section {
                Text(CustomerCRMDirectory.shared.name(for: conversation)).font(.headline)
                if let plan { Text("+\(plan.phone)").monospacedDigit() }
                Text("בחר מאילו מספרי WhatsApp לבצע חסימה. התוצאה חלה גם ב־WhatsApp המקורי של כל מספר שנבחר.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let plan {
                Section("המספרים שלך") {
                    Button("בחר את כל המספרים (\(plan.targets.count))") { selected = Set(plan.targets.map(\.accountID)) }.disabled(busy)
                    Button("רק המספר של השיחה") { selected = [currentAccount] }.disabled(busy)
                    ForEach(plan.targets) { target in
                        Button {
                            if selected.contains(target.id) { selected.remove(target.id) } else { selected.insert(target.id) }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(target.id) ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(target.name).foregroundStyle(.primary)
                                    if !target.phone.isEmpty { Text(target.phone).font(.caption).foregroundStyle(.secondary) }
                                    if let result = results[target.id] {
                                        Text(result).font(.caption).foregroundStyle(failed.contains(target.id) ? Color.orange : Color.secondary)
                                    }
                                }
                                Spacer()
                                if confirmed.contains(target.id) { Image(systemName: "checkmark.shield.fill").foregroundStyle(.green) }
                            }
                        }.disabled(busy)
                    }
                }
                Section {
                    Button("בדוק מצב חסימה במספרים שנבחרו") { operation = Task { await checkStates() } }.disabled(busy || selected.isEmpty)
                    Button("חסום ב־\(selected.count) מספרים", role: .destructive) { desired = true; confirm = true }.disabled(busy || selected.isEmpty)
                    Button("בטל חסימה במספרים שנבחרו") { desired = false; confirm = true }.disabled(busy || selected.isEmpty)
                    if busy { ProgressView("ממתין לאישור מכל חשבון…") }
                    Text("חשבון מנותק עלול להיכשל. רק ׳אושר׳ מציין ש־WhatsApp אישר את הפעולה. לא מתבצעת שליחה חוזרת אוטומטית, וחשבונות שיחוברו בעתיד לא ייחסמו אוטומטית.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("החסימה אינה מוחקת היסטוריה ואינה משנה את רשימות התפוצה שלך.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let errorText { Section { Text(errorText).foregroundStyle(.secondary) } }
            if plan == nil && busy { ProgressView("טוען חשבונות…") }
            if !busy { Button("רענן רשימת חשבונות") { Task { await load() } } }
        }
        .navigationTitle("חסימה בכל המספרים")
        .navigationBarTitleDisplayMode(.inline)
        .privacySensitive()
        .task { await load() }
        .onDisappear { operation?.cancel() }
        .confirmationDialog(desired ? "לחסום ב־\(selected.count) מספרים?" : "לבטל חסימה ב־\(selected.count) מספרים?", isPresented: $confirm, titleVisibility: .visible) {
            Button(desired ? "חסום ב־WhatsApp" : "בטל חסימה", role: desired ? .destructive : nil) {
                operation = Task { await apply() }
            }
        } message: { Text("הפעולה תחול על המספרים שבחרת ותסתנכרן עם WhatsApp שלהם.") }
    }
    private func load() async {
        guard !busy, UserWorkspace.id == workspace else { return }; busy = true; defer { busy = false }
        do {
            let value = try await ContactUpgradeAPI.plan(conversation, workspace: workspace)
            plan = value; selected = [currentAccount]; errorText = nil
        } catch is CancellationError { }
        catch { errorText = "לא ניתן לטעון את המספרים. ודא שהלקוח הוא איש קשר פרטי ושמספר הטלפון שלו מזוהה." }
    }
    private func apply() async {
        guard !busy, UserWorkspace.id == workspace, let plan else { return }
        busy = true; defer { busy = false }
        let scope = UserWorkspace.id, action = desired
        let targets = plan.targets.filter { selected.contains($0.id) }
        results = [:]; confirmed = []; failed = []
        for target in targets { results[target.id] = "ממתין לביצוע" }
        // Serial dispatch keeps load bounded and preserves a clear per-account
        // result. No speculative retry when a response was lost.
        for target in targets {
            guard !Task.isCancelled, UserWorkspace.id == scope else { return }
            results[target.id] = "מבצע…"
            do {
                try await ContactUpgradeAPI.block(target.id, source: conversation, desired: action, workspace: workspace)
                guard !Task.isCancelled, UserWorkspace.id == scope else { return }
                confirmed.insert(target.id)
                results[target.id] = action ? "חסימה אושרה ב־WhatsApp" : "ביטול חסימה אושר ב־WhatsApp"
            } catch {
                guard !Task.isCancelled, UserWorkspace.id == scope else { return }
                failed.insert(target.id); results[target.id] = "לא אושר — רענן מצב בחשבון לפני ניסיון נוסף"
            }
        }
    }
    private func checkStates() async {
        guard !busy, UserWorkspace.id == workspace, let plan else { return }
        busy = true; defer { busy = false }
        let scope = UserWorkspace.id
        for target in plan.targets.filter({ selected.contains($0.id) }) {
            guard !Task.isCancelled, UserWorkspace.id == scope else { return }
            do {
                let blocked = try await ContactUpgradeAPI.blocked(target.id, canonicalJID: plan.customerJID, workspace: workspace)
                guard !Task.isCancelled, UserWorkspace.id == scope else { return }
                failed.remove(target.id); confirmed.insert(target.id)
                results[target.id] = blocked ? "מצב נוכחי ב־WhatsApp: חסום" : "מצב נוכחי ב־WhatsApp: לא חסום"
            } catch {
                guard !Task.isCancelled, UserWorkspace.id == scope else { return }
                confirmed.remove(target.id); failed.insert(target.id)
                results[target.id] = "לא ניתן לאמת מצב — ייתכן שהחשבון מנותק"
            }
        }
    }
}
