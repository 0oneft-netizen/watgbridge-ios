import SwiftUI
import PhotosUI
import UIKit

private func automationStateLabel(_ state: String) -> String {
    switch state {
    case "generating": return "AI מנסח תשובה"
    case "approved": return "אושרה וממתינה לשליחה"
    case "draft": return "טיוטה לבדיקה"
    default: return broadcastStatus(state)
    }
}
struct CustomerAutomationCenter: View {
    @State private var campaigns: [AutomationCampaignRecord] = []
    @State private var error: String?
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        List {
            Section("תפוצה חדשה") {
                NavigationLink { AutomationAudienceView(source: "all") } label: { Label("בחירה מכל הצ׳אטים", systemImage: "paperplane") }
                NavigationLink { AutomationAudienceView(source: "stale") } label: { Label("לקוחות שלא דיברו לאחרונה", systemImage: "clock.arrow.circlepath") }
            }
            Section("מענה ללקוחות חדשים") {
                NavigationLink { CustomerAutomationSettingsView() } label: { Label("הגדרות אוטומציה ו־AI", systemImage: "slider.horizontal.3") }
                NavigationLink { CustomerAutomationAIInbox() } label: { Label("תשובות AI ומעקב", systemImage: "sparkles") }
            }
            Section("תפוצות שנוצרו") {
                if campaigns.isEmpty { Text("התפוצות שתיצור כאן יופיעו ברשימה.").foregroundStyle(.secondary) }
                ForEach(campaigns) { record in
                    NavigationLink { AutomationCampaignDetail(id: record.id) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(record.text.isEmpty ? "תפוצת תמונה" : record.text).lineLimit(2)
                            Text("\(broadcastStatus(record.state)) · \(record.sent)/\(record.total) נשלחו").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
        }
        .listStyle(.insetGrouped).modifier(WhatsAppListStyle())
        .navigationTitle("מרכז תפוצות ו־AI")
        .refreshable { await load() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled { await load(); do { try await Task.sleep(for: .seconds(10)) } catch { return } }
        }
    }
    @MainActor private func load() async {
        do { campaigns = try await CustomerAutomationAPI.shared.request("campaigns"); error = nil }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
struct AutomationAudienceView: View {
    let source: String
    @State private var members: [AutomationAudienceMember] = []
    @State private var configuration: CustomerAutomationConfiguration?
    @State private var selected = Set<String>()
    @State private var accountID = ""
    @State private var query = ""
    @State private var includeGroups = false
    @State private var showComposer = false
    @State private var loading = false
    @State private var loadVersion = 0
    @State private var error: String?
    @ObservedObject private var sessions = SessionDirectory.shared
    private var visible: [AutomationAudienceMember] {
        members.filter { (accountID.isEmpty || $0.accountID == accountID) && (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.jid.localizedCaseInsensitiveContains(query)) }
    }
    private var chosen: [AutomationAudienceMember] { members.filter { selected.contains($0.id) } }
    var body: some View {
        List {
            Section {
                Picker("חשבון WhatsApp", selection: $accountID) {
                    Text("כל החשבונות שלי").tag("")
                    ForEach(Array(Set(members.map(\.accountID)).union(sessions.sessions.keys)).sorted(), id: \.self) { id in Text(sessions.name(for: id)).tag(id) }
                }
                if source == "all" { Toggle("הצג גם צ׳אטים קבוצתיים", isOn: $includeGroups) }
                if source == "stale" {
                    Text("ללא שיחה במשך \(configuration?.settings.staleHours ?? 168) שעות. הודעה שלך או של הלקוח מחדשת את זמן הפעילות.")
                        .font(.footnote).foregroundStyle(.secondary)
                    NavigationLink("שינוי פרק הזמן והרשימה האוטומטית") { CustomerAutomationSettingsView() }
                }
                Button("בחר את כל המוצגים (\(visible.count))") { selected.formUnion(visible.map(\.id)) }.disabled(loading)
                if !selected.isEmpty { Button("נקה בחירה (\(selected.count))") { selected.removeAll() } }
                Text("בחירה לפי חשבון: אותו איש קשר בשני חשבונות הוא שני נמענים נפרדים. החשבון שמופיע לידו הוא החשבון שישלח.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("צ׳אטים · \(visible.count)") {
                if loading { ProgressView() }
                ForEach(visible) { member in
                    Button {
                        if selected.contains(member.id) { selected.remove(member.id) } else { selected.insert(member.id) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selected.contains(member.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(WhatsAppVisualDesign.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.title).foregroundStyle(.primary)
                                Text(sessions.name(for: member.accountID)).font(.caption).foregroundStyle(.secondary)
                                Text(Date(timeIntervalSince1970: TimeInterval(member.lastAt)), format: .dateTime.day().month().year().hour().minute())
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 3)
                    }.buttonStyle(.plain)
                }
                if !loading && visible.isEmpty { Text("אין צ׳אטים שמתאימים לסינון.").foregroundStyle(.secondary) }
            }
            if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
        }
        .modifier(WhatsAppListStyle())
        .navigationTitle(source == "stale" ? "לא דיברנו לאחרונה" : "בחירת נמענים")
        .searchable(text: $query, prompt: "שם או מספר")
        .safeAreaInset(edge: .bottom) {
            Button("המשך עם \(chosen.count) נמענים") { showComposer = true }
                .font(.headline).frame(maxWidth: .infinity).padding()
                .background(WhatsAppVisualDesign.accent, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                .disabled(chosen.isEmpty || loading).padding(12).background(.regularMaterial)
        }
        .sheet(isPresented: $showComposer) {
            AutomationCampaignComposer(source: source, accountID: accountID, members: chosen, hours: configuration?.settings.staleHours ?? 168, includeGroups: includeGroups)
        }
        .onChange(of: includeGroups) { Task { await load() } }
        .onChange(of: accountID) { Task { await load() } }
        .onAppear { Task { await load() } }
        .refreshable { await load() }
    }
    @MainActor private func load() async {
        loadVersion += 1
        let version = loadVersion
        loading = true
        defer { if loadVersion == version { loading = false } }
        let groups = includeGroups
        let account = accountID
        do {
            let config: CustomerAutomationConfiguration = try await CustomerAutomationAPI.shared.request("settings")
            let rows: [AutomationAudienceMember] = try await CustomerAutomationAPI.shared.request("recipients", query: [URLQueryItem(name: "source", value: source), URLQueryItem(name: "account_id", value: account), URLQueryItem(name: "include_groups", value: groups ? "true" : "false")])
            guard version == loadVersion, groups == includeGroups, account == accountID else { return }
            configuration = config
            members = rows; selected.formIntersection(rows.map(\.id)); error = nil
        } catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
struct AutomationCampaignComposer: View {
    let source: String
    let accountID: String
    let members: [AutomationAudienceMember]
    let hours: Int
    let includeGroups: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var interval = 60
    @State private var photo: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var loadingImage = false
    @State private var key = UUID().uuidString
    @State private var busy = false
    @State private var error: String?
    @State private var createdID: Int64?
    var body: some View {
        NavigationStack {
            Form {
                Section("הודעה ל־\(members.count) צ׳אטים") {
                    TextEditor(text: $text).frame(minHeight: 130)
                    Text("אפשר לשלב {name} ו־{phone}. מספר לא מזוהה לא יומצא.").font(.caption).foregroundStyle(.secondary)
                    PhotosPicker(selection: $photo, matching: .images) { Label("צירוף תמונה", systemImage: "photo") }
                    if loadingImage { ProgressView("מכין תמונה…") }
                    if let imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180)
                        Button("הסר תמונה", role: .destructive) { self.imageData = nil; photo = nil }
                    }
                }
                Section("קצב השליחה") {
                    Picker("מרווח בין נמענים", selection: $interval) {
                        Text("דקה").tag(60); Text("שתי דקות").tag(120); Text("חמש דקות").tag(300)
                    }
                    Text("לפחות \(max(0, members.count - 1) * interval / 60) דקות. התור ממשיך בשרת כשהאפליקציה סגורה.").font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("צור טיוטת תפוצה לבדיקה") { Task { await create() } }
                        .disabled(busy || loadingImage || (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData == nil))
                    if busy { ProgressView() }
                    if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .disabled(busy).navigationTitle("תפוצה חדשה")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("סגור") { dismiss() }.disabled(busy) } }
            .navigationDestination(isPresented: Binding(get: { createdID != nil }, set: { if !$0 { createdID = nil } })) {
                if let createdID { AutomationCampaignDetail(id: createdID) }
            }
            .task(id: photo) { await loadImage() }
            .onChange(of: createdID) { if createdID == nil { key = UUID().uuidString } }
        }
    }
    @MainActor private func loadImage() async {
        guard let item = photo else { return }; loadingImage = true; defer { loadingImage = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), data.count <= 40 * 1024 * 1024,
                  let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { throw URLError(.cannotDecodeContentData) }
            try Task.checkCancellation()
            let scale = min(1, 1600 / max(image.size.width, image.size.height))
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            guard let jpeg = resized.jpegData(compressionQuality: 0.85), jpeg.count <= 8 * 1024 * 1024 else { throw URLError(.dataLengthExceedsMaximum) }
            imageData = jpeg; error = nil
        } catch is CancellationError {} catch { self.error = "לא ניתן להכין את התמונה. נסה תמונה אחרת." }
    }
    @MainActor private func create() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            var body: [String: Any] = ["request_key": key, "source": source, "account_id": accountID, "stale_hours": hours, "include_groups": includeGroups,
                "text": text, "interval_seconds": interval, "selected": members.map(\.id)]
            if let imageData { body["image"] = imageData.base64EncodedString(); body["image_mime"] = "image/jpeg" }
            let result: FeatureCreated = try await CustomerAutomationAPI.shared.request("campaigns", method: "POST", body: body)
            createdID = result.id; error = nil
        } catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
struct AutomationCampaignDetail: View {
    let id: Int64
    @State private var record: AutomationCampaignRecord?
    @State private var pages: [Int64] = [0]
    @State private var action: String?
    @State private var busy = false
    @State private var error: String?
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        List {
            if let record {
                Section {
                    Text(record.text)
                    if record.hasImage { Label("כוללת תמונה", systemImage: "photo") }
                    LabeledContent("מצב", value: broadcastStatus(record.state))
                    LabeledContent("נשלחו", value: "\(record.sent) מתוך \(record.total)")
                    LabeledContent("מרווח", value: "\(record.intervalSeconds / 60) דקות")
                    if record.state == "draft" || record.state == "paused" { Button("התחל / המשך שליחה") { action = "start" }.disabled(busy) }
                    if record.state == "running" { Button("השהה") { Task { await change("pause") } }.disabled(busy) }
                    if ["draft", "running", "paused"].contains(record.state) { Button("בטל את השליחות שנותרו", role: .destructive) { action = "cancel" }.disabled(busy) }
                    Text("שליחה שכבר התחילה עשויה להסתיים גם לאחר ביטול. שליחה לא ודאית לא נשלחת שוב אוטומטית.").font(.caption).foregroundStyle(.secondary)
                }
                Section("נמענים · עמוד \(pages.count)") {
                    HStack {
                        if pages.count > 1 { Button("הקודם") { pages.removeLast(); Task { await load() } } }
                        Spacer()
                        if record.hasMore { Button("הבא") { pages.append(record.nextItemID); Task { await load() } } }
                    }
                    ForEach(record.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                            Text("\(SessionDirectory.shared.name(for: item.accountID)) · \(broadcastStatus(item.state))").font(.caption).foregroundStyle(.secondary)
                            if !item.lastError.isEmpty { Text(item.lastError).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("מעקב תפוצה")
        .confirmationDialog(action == "cancel" ? "לבטל את התפוצה?" : "לשלוח לנמענים שבחרת?", isPresented: Binding(get: { action != nil }, set: { if !$0 { action = nil } }), titleVisibility: .visible) {
            Button("אישור") { if let action { self.action = nil; Task { await change(action) } } }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled { await load(); do { try await Task.sleep(for: .seconds(5)) } catch { return } }
        }
    }
    @MainActor private func load() async {
        let after = pages.last ?? 0
        do {
            let rows: [AutomationCampaignRecord] = try await CustomerAutomationAPI.shared.request("campaigns", query: [URLQueryItem(name: "id", value: String(id)), URLQueryItem(name: "after", value: String(after))])
            guard after == pages.last else { return }
            record = rows.first; error = nil
        }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
    @MainActor private func change(_ action: String) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let _: FeatureAccepted = try await CustomerAutomationAPI.shared.request("campaign-action", method: "POST", body: ["id": id, "action": action]); await load() }
        catch is CancellationError {} catch { self.error = error.localizedDescription }
    }
}
