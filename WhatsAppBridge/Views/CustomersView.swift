import SwiftUI
import UniformTypeIdentifiers

struct CustomersView: View {
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @State private var searchText = ""
    @State private var addCustomer = false
    @State private var createGroup = false
    @State private var deleteGroup: CRMGroup?
    @State private var importing = false
    @State private var restoring = false
    @State private var pendingImport: Data?
    @State private var exporting = false
    @State private var document = CRMBackupDocument(data: Data())
    @State private var error: String?
    private var customers: [CRMCustomer] {
        crm.state.customers.filter {
            searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText)
            || $0.phone.contains(searchText) || $0.accountName.localizedCaseInsensitiveContains(searchText)
        }
    }
    private var groups: [CRMGroup] {
        crm.state.groups.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        NavigationStack {
            List {
                if let message = error ?? crm.lastError {
                    Section {
                        Text(message).foregroundStyle(.red)
                        Button("ניסיון טעינה נוסף") { Task { error = nil; await crm.refresh() } }
                    }
                }
                Section("קבוצות לקוחות") {
                    ForEach(groups) { group in
                        NavigationLink { CustomerGroupDetail(groupID: group.id) } label: {
                            HStack {
                                Image(systemName: "person.2.fill").foregroundStyle(WhatsAppVisualDesign.accent)
                                VStack(alignment: .leading) {
                                    Text(group.name)
                                    if group.autoSend { Text("הודעה אוטומטית בצירוף").font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                Text(String(crm.state.memberships.filter { $0.groupID == group.id }.count)).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("מחיקת קבוצה", role: .destructive) { deleteGroup = group }
                        }
                    }
                    Button { createGroup = true } label: { Label("יצירת קבוצה", systemImage: "plus") }
                }
                Section("לקוחות שמורים · \(crm.state.customers.count)") {
                    if customers.isEmpty {
                        Text(searchText.isEmpty ? "שמור לקוחות מתוך צ׳אט או דרך בחירת לקוח. רק מי שתבחר יופיע כאן." : "לא נמצאו לקוחות")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(customers) { customer in
                        NavigationLink { CustomerInfoView(conversation: customer.conversation) } label: { CRMSavedCustomerRow(customer: customer) }
                    }
                    Button { addCustomer = true } label: { Label("בחירת לקוח לשמירה", systemImage: "person.badge.plus") }
                }
            }
            .modifier(WhatsAppListStyle())
            .navigationTitle("Customers")
            .searchable(text: $searchText, prompt: "חיפוש לקוחות וקבוצות")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { addCustomer = true } label: { Label("שמירת לקוח", systemImage: "person.badge.plus") }
                        Button { createGroup = true } label: { Label("קבוצה חדשה", systemImage: "person.2.badge.plus") }
                        Button {
                            Task {
                                await crm.refresh()
                                guard crm.lastError == nil else { return }
                                do { document = CRMBackupDocument(data: try crm.backup()); exporting = true } catch { self.error = error.localizedDescription }
                            }
                        } label: { Label("ייצוא לקוחות שמורים לגיבוי", systemImage: "square.and.arrow.up") }
                        Button { importing = true } label: { Label("ייבוא מגיבוי", systemImage: "square.and.arrow.down") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $addCustomer) { CRMCustomerPicker() }
            .sheet(isPresented: $createGroup) { CustomerGroupEditor(group: .empty) }
            .alert("מחיקת הקבוצה?", isPresented: Binding(get: { deleteGroup != nil }, set: { if !$0 { deleteGroup = nil } })) {
                Button("ביטול", role: .cancel) { deleteGroup = nil }
                Button("מחיקה", role: .destructive) {
                    guard let group = deleteGroup else { return }; deleteGroup = nil
                    Task { do { try await crm.delete(group: group) } catch { self.error = error.localizedDescription } }
                }
            } message: { Text("הלקוחות יישארו שמורים. הודעות שעדיין ממתינות לשליחה עבור הקבוצה יבוטלו.") }
            .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "watgbridge-saved-customers") { result in
                if case .failure(let failure) = result { error = failure.localizedDescription }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 8 * 1024 * 1024 else { throw CRMError(message: "קובץ הגיבוי גדול מדי") }
                    let data = try Data(contentsOf: url)
                    let backup = try JSONDecoder().decode(CRMBackup.self, from: data)
                    guard backup.formatVersion == 1 else { throw CRMError(message: "קובץ גיבוי לא נתמך") }
                    pendingImport = data
                    restoring = true
                } catch { self.error = error.localizedDescription }
            }
            .alert("לייבא את הגיבוי?", isPresented: $restoring) {
                Button("ביטול", role: .cancel) { pendingImport = nil }
                Button("ייבוא") {
                    guard let data = pendingImport else { return }; pendingImport = nil
                    Task { do { try await crm.restore(data: data) } catch { self.error = error.localizedDescription } }
                }
            } message: { Text("לקוחות וקבוצות חסרים יתווספו. נתונים קיימים יישמרו, ולא יישלחו הודעות בעקבות הייבוא.") }
            .refreshable { await crm.refresh() }
            .task { await crm.refresh() }
        }
    }
}
