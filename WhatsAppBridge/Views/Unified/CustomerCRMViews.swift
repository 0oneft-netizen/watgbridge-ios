import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct CRMBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct CustomerSaveView: View {
    let conversation: Conversation
    var initialGroupID: Int64? = nil
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @ObservedObject private var sessions = SessionDirectory.shared
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selected: Set<Int64> = []
    @State private var initialized = false
    @State private var ready = false
    @State private var error: String?
    @State private var newGroup = false

    private var phone: String { crm.customer(for: conversation)?.phone.nonEmpty ?? ChatIdentity.customerPhone(conversation: conversation) }
    private var newAutomaticGroups: [CRMGroup] {
        let existing = crm.customer(for: conversation).map { crm.groupIDs(for: $0.id) } ?? []
        var previousJobs: Set<Int64> = []
        if let customerID = crm.customer(for: conversation)?.id {
            previousJobs = Set(crm.state.jobs.filter { $0.customerID == customerID }.map(\.groupID))
        }
        return crm.state.groups.filter { group in
            group.autoSend && selected.contains(group.id) && !existing.contains(group.id) && !previousJobs.contains(group.id)
        }
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("פרטי הלקוח") {
                    TextField("שם לשמירה", text: $name)
                    if !phone.isEmpty {
                        LabeledContent("מספר אמיתי", value: phone)
                        Button { UIPasteboard.general.string = phone } label: { Label("העתקת מספר", systemImage: "doc.on.doc") }
                    }
                    SessionMiniBadge(name: sessions.name(for: conversation.accountID))
                }
                Section {
                    if crm.state.groups.isEmpty { Text("צור קבוצה או שמור את הלקוח ללא קבוצה").foregroundStyle(.secondary) }
                    ForEach(crm.state.groups) { group in
                        Button {
                            if selected.contains(group.id) { selected.remove(group.id) } else { selected.insert(group.id) }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(group.id) ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading) {
                                    Text(group.name).foregroundStyle(.primary)
                                    if group.autoSend { Text("הודעה אוטומטית בצירוף חדש").font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }
                    Button { newGroup = true } label: { Label("קבוצה חדשה", systemImage: "plus") }
                } header: { Text("בחירת קבוצות") }
                ForEach(newAutomaticGroups) { group in
                    Section("ההודעה שתישלח · \(group.name)") {
                        Text(group.welcomeMessage.replacingOccurrences(of: "{name}", with: name).replacingOccurrences(of: "{phone}", with: phone))
                            .font(.subheadline)
                    }
                }
                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                        if !ready { Button("ניסיון טעינה נוסף") { Task { await initialize() } } }
                    }
                }
                Section {
                    Button {
                        Task {
                            do {
                                try await crm.save(conversation: conversation, name: name, groups: selected)
                                Haptics.success()
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                        }
                    } label: {
                        HStack { Spacer(); if crm.isSaving { ProgressView() } else { Text(newAutomaticGroups.isEmpty ? "שמירת לקוח" : "שמירה וצירוף לקבוצות") }; Spacer() }
                    }
                    .disabled(!ready || crm.isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: { Text("השם נשמר באפליקציה. מספר הטלפון וחשבון הוואטסאפ נשארים כפי שהם.") }
            }
            .navigationTitle("שמירת לקוח")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() } } }
            .sheet(isPresented: $newGroup) { CustomerGroupEditor(group: .empty) }
            .task { await initialize() }
        }
    }
    @MainActor
    private func initialize() async {
        await crm.refresh()
        if let message = crm.lastError { error = message; return }
        if !initialized {
            name = crm.name(for: conversation)
            if let customer = crm.customer(for: conversation) { selected = crm.groupIDs(for: customer.id) }
            if let initialGroupID { selected.insert(initialGroupID) }
            initialized = true
        }
        error = nil
        ready = true
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

struct CustomerGroupEditor: View {
    let group: CRMGroup
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var message = ""
    @State private var automatic = false
    @State private var error: String?
    @State private var initialized = false
    var body: some View {
        NavigationStack {
            Form {
                Section("שם הקבוצה") { TextField("לדוגמה: לקוחות VIP", text: $name) }
                Section {
                    Toggle("שליחה אוטומטית בצירוף לקוח", isOn: $automatic)
                    TextEditor(text: $message).frame(minHeight: 150)
                } header: { Text("הודעה ללקוח") } footer: {
                    Text("ניתן לשלב {name} ו־{phone}. ההודעה תישלח מהוואטסאפ שאליו הלקוח פנה. שינוי הנוסח לא שולח הודעות לחברים קיימים.")
                }
                if let error { Text(error).foregroundStyle(.red) }
                Button("שמירת קבוצה") {
                    Task {
                        let value = CRMGroup(id: group.id, name: name, welcomeMessage: message, autoSend: automatic, createdAt: group.createdAt, updatedAt: group.updatedAt)
                        do { try await crm.save(group: value); dismiss() } catch { self.error = error.localizedDescription }
                    }
                }
                .disabled(crm.isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (automatic && message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
            .navigationTitle(group.id == 0 ? "קבוצה חדשה" : "עריכת קבוצה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() } } }
            .onAppear { if !initialized { name = group.name; message = group.welcomeMessage; automatic = group.autoSend; initialized = true } }
        }
    }
}

struct CustomerGroupDetail: View {
    let groupID: Int64
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @State private var editing: CRMGroup?
    @State private var retryJob: CRMWelcomeJob?
    @State private var addCustomers = false
    @State private var exporting = false
    @State private var document = CRMBackupDocument(data: Data())
    @State private var error: String?
    private var group: CRMGroup? { crm.state.groups.first { $0.id == groupID } }
    private var members: [CRMCustomer] {
        let ids = Set(crm.state.memberships.filter { $0.groupID == groupID }.map(\.customerID))
        return crm.state.customers.filter { ids.contains($0.id) }
    }
    private var jobs: [CRMWelcomeJob] {
        let ids = Set(members.map(\.id))
        return crm.state.jobs.filter { $0.groupID == groupID && ids.contains($0.customerID) }
    }
    var body: some View {
        List {
            if let group {
                Section {
                    LabeledContent("שליחה אוטומטית", value: group.autoSend ? "פעילה" : "כבויה")
                    if !group.welcomeMessage.isEmpty { Text(group.welcomeMessage).font(.subheadline) }
                    Button("עריכת הקבוצה וההודעה") { editing = group }
                    Button("צירוף לקוח") { addCustomers = true }
                    NavigationLink { CustomerBroadcastsView(groupID: groupID) } label: {
                        Label("הודעות תפוצה לקבוצה", systemImage: "paperplane.fill")
                    }
                }
            }
            Section("לקוחות · \(members.count)") {
                if members.isEmpty { Text("עדיין לא בחרת לקוחות לקבוצה").foregroundStyle(.secondary) }
                ForEach(members) { customer in
                    NavigationLink { CustomerInfoView(conversation: customer.conversation) } label: { CRMSavedCustomerRow(customer: customer) }
                }
            }
            Section("הודעות בעת הצירוף") {
                ForEach(jobs) { job in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(crm.state.customers.first { $0.id == job.customerID }?.displayName ?? "לקוח")
                        Text(job.statusText).font(.caption).foregroundStyle(.secondary)
                        if !job.lastError.isEmpty { Text(job.lastError).font(.caption2).foregroundStyle(.secondary) }
                        if (job.state == "failed" || job.state == "uncertain") && group?.autoSend == true {
                            Button("ניסיון שליחה נוסף") { retryJob = job }.disabled(crm.isSaving)
                        }
                    }
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .navigationTitle(group?.name ?? "קבוצת לקוחות")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { do { document = CRMBackupDocument(data: try crm.backup(groupID: groupID)); exporting = true } catch { self.error = error.localizedDescription } } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(item: $editing) { CustomerGroupEditor(group: $0) }
        .sheet(isPresented: $addCustomers) { CRMCustomerPicker(preselectedGroup: groupID) }
        .alert("לשלוח שוב?", isPresented: Binding(get: { retryJob != nil }, set: { if !$0 { retryJob = nil } })) {
            Button("ביטול", role: .cancel) { retryJob = nil }
            Button("שליחה נוספת") {
                guard let job = retryJob else { return }; retryJob = nil
                Task { do { try await crm.retry(job: job) } catch { self.error = error.localizedDescription } }
            }
        } message: { Text("ייתכן שהלקוח כבר קיבל את ההודעה לפני השגיאה. ניסיון נוסף עשוי לשלוח אותה שוב.") }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "watgbridge-customer-group") { result in
            if case .failure(let failure) = result { error = failure.localizedDescription }
        }
        .refreshable { await crm.refresh() }
        .task {
            while !Task.isCancelled {
                await crm.refresh()
                do { try await Task.sleep(nanoseconds: 3_000_000_000) } catch { break }
            }
        }
    }
}

struct CRMSavedCustomerRow: View {
    let customer: CRMCustomer
    var body: some View {
        HStack(spacing: 12) {
            CustomerAvatarView(jid: customer.jid, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.displayName).font(.headline)
                if !customer.phone.isEmpty { Text(customer.phone).font(.caption).foregroundStyle(.secondary) }
                SessionMiniBadge(name: customer.accountName.isEmpty ? customer.accountID : customer.accountName)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CRMCustomerPicker: View {
    var preselectedGroup: Int64? = nil
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var query = ""
    @State private var error: String?
    @State private var selection: Conversation?
    var body: some View {
        NavigationStack {
            List {
                if let error { Text(error).foregroundStyle(.red) }
                ForEach(conversations.filter { ($0.jid.hasSuffix("@s.whatsapp.net") || $0.jid.hasSuffix("@lid")) && (query.isEmpty || crm.name(for: $0).localizedCaseInsensitiveContains(query) || ChatIdentity.customerPhone(conversation: $0).contains(query)) }) { conversation in
                    Button { selection = conversation } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(crm.name(for: conversation)).foregroundStyle(.primary)
                            Text(ChatIdentity.customerPhone(conversation: conversation)).font(.caption).foregroundStyle(.secondary)
                            SessionMiniBadge(name: SessionDirectory.shared.name(for: conversation.accountID))
                        }
                    }
                }
            }
            .navigationTitle("בחירת לקוח")
            .searchable(text: $query)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("סיום") { dismiss() } } }
            .sheet(item: $selection) { conversation in CustomerSaveView(conversation: conversation, initialGroupID: preselectedGroup) }
            .task {
                do {
                    conversations = try await APIClient.shared.fetchConversations()
                    await crm.refresh()
                    let existing = Set(conversations.map(\.id))
                    conversations += crm.state.customers.map(\.conversation).filter { !existing.contains($0.id) }
                } catch { self.error = error.localizedDescription }
            }
        }
    }
}
