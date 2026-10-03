import SwiftUI

func broadcastStatus(_ state: String) -> String {
    switch state {
    case "draft": return "טיוטה — טרם התחילה"
    case "running": return "פעילה"
    case "paused": return "מושהית"
    case "completed": return "הסתיימה"
    case "cancelled": return "בוטלה"
    case "pending": return "ממתין"
    case "sending": return "בשליחה"
    case "sent": return "נשלח"
    case "skipped": return "דולג — חסום, מוחרג או הוסר מהקבוצה"
    case "failed": return "בדיקה נכשלה — לא נשלח"
    case "uncertain": return "השליחה לא אומתה — לא יישלח שוב אוטומטית"
    default: return state
    }
}
struct CustomerBroadcastsView: View {
    let groupID: Int64
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @State private var campaigns: [CustomerBroadcast] = []
    @State private var create = false
    @State private var error: String?
    var body: some View {
        List {
            Section {
                Button("תפוצה חדשה לקבוצה") { create = true }
                Text("כל לקוח יקבל הודעה פרטית מהסשן שלו. התור נשמר בשרת וממשיך כשהאפליקציה סגורה.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(campaigns.filter { $0.groupID == groupID }) { campaign in
                NavigationLink { CustomerBroadcastDetail(id: campaign.id) } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(campaign.text).lineLimit(2)
                        Text("\(broadcastStatus(campaign.state)) · \(campaign.items.filter { $0.state == "sent" }.count)/\(campaign.items.count) נשלחו")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if let error { Text(error).foregroundStyle(.secondary) }
        }
        .navigationTitle("תפוצות הקבוצה")
        .sheet(isPresented: $create) { CustomerBroadcastComposer(groupID: groupID) }
        .task {
            while !Task.isCancelled {
                do { campaigns = try await CustomerFeaturesAPI.shared.request("broadcasts"); error = nil }
                catch { if !Task.isCancelled { self.error = error.localizedDescription } }
                do { try await Task.sleep(for: .seconds(3)) } catch { break }
            }
        }
    }
}
struct CustomerBroadcastComposer: View {
    let groupID: Int64
    @ObservedObject private var crm = CustomerCRMDirectory.shared
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var interval = 60
    @State private var selected = Set<Int64>()
    @State private var requestKey = UUID().uuidString
    @State private var busy = false
    @State private var error: String?
    @State private var createdID: Int64 = 0
    @State private var showCreated = false
    private var members: [CRMCustomer] {
        let ids = Set(crm.state.memberships.filter { $0.groupID == groupID }.map(\.customerID))
        return crm.state.customers.filter { ids.contains($0.id) }
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("הודעה פרטית לכל לקוח") {
                    TextEditor(text: $text).frame(minHeight: 130)
                    Text("אפשר לשלב {name} ו־{phone}.").font(.footnote).foregroundStyle(.secondary)
                    Picker("מרווח בין הודעות", selection: $interval) {
                        Text("הודעה בכל דקה").tag(60)
                        Text("הודעה בכל שתי דקות").tag(120)
                    }
                }
                Section("נמענים · \(selected.count)") {
                    Button(selected.count == members.count ? "בטל בחירת כולם" : "בחר את כל חברי הקבוצה") {
                        selected = selected.count == members.count ? [] : Set(members.map(\.id))
                    }
                    ForEach(members) { customer in
                        Button {
                            if selected.contains(customer.id) { selected.remove(customer.id) } else { selected.insert(customer.id) }
                        } label: {
                            HStack { Text(customer.displayName); Spacer(); Image(systemName: selected.contains(customer.id) ? "checkmark.circle.fill" : "circle") }
                        }
                    }
                }
                Section {
                    Text("זמן מינימלי משוער: \(max(0, selected.count - 1) * interval / 60) דקות. תפוצות אחרות וזמן השליחה עשויים להאריך אותו.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("הכן תפוצה לבדיקה") { Task { await prepare() } }
                        .disabled(busy || selected.isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if busy { ProgressView() }
                    if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .disabled(busy)
            .navigationTitle("תפוצה חדשה")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("סגור") { dismiss() }.disabled(busy) } }
            .navigationDestination(isPresented: $showCreated) { CustomerBroadcastDetail(id: createdID) }
            .task { await crm.refresh() }
        }
    }
    @MainActor private func prepare() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            let result: FeatureCreated = try await CustomerFeaturesAPI.shared.request("broadcasts", method: "POST", body: ["request_key": requestKey, "group_id": groupID, "text": text, "interval_seconds": interval, "customer_ids": Array(selected).sorted()])
            createdID = result.id; showCreated = true; error = nil
        } catch { self.error = error.localizedDescription }
    }
}
struct CustomerBroadcastDetail: View {
    let id: Int64
    @State private var campaign: CustomerBroadcast?
    @State private var busy = false
    @State private var error: String?
    @State private var pendingAction: String?
    var body: some View {
        List {
            if let c = campaign {
                Section {
                    Text(c.text)
                    LabeledContent("מצב", value: broadcastStatus(c.state))
                    LabeledContent("מרווח", value: c.intervalSeconds == 60 ? "דקה" : "שתי דקות")
                    LabeledContent("נשלחו", value: "\(c.items.filter { $0.state == "sent" }.count) מתוך \(c.items.count)")
                    if c.state == "draft" || c.state == "paused" { Button(c.state == "draft" ? "התחל שליחה" : "המשך שליחה") { pendingAction = "start" }.disabled(busy) }
                    if c.state == "running" { Button("השהה שליחה") { Task { await action("pause") } }.disabled(busy) }
                    if ["draft", "paused", "running"].contains(c.state) { Button("בטל את השליחות שנותרו", role: .destructive) { pendingAction = "cancel" }.disabled(busy) }
                    Text("השהיה או ביטול לא מחזירים הודעה שכבר התחילה להישלח. שליחה לא ודאית אינה נשלחת שוב אוטומטית.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("נמענים") {
                    ForEach(c.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                            Text("\(item.accountID) · \(broadcastStatus(item.state))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("תפוצה")
        .confirmationDialog(pendingAction == "cancel" ? "לבטל את התפוצה?" : "לשלוח לנמענים שבחרת?", isPresented: Binding(get: { pendingAction != nil }, set: { if !$0 { pendingAction = nil } }), titleVisibility: .visible) {
            Button("אישור") { guard let value = pendingAction else { return }; pendingAction = nil; Task { await action(value) } }
        }
        .task {
            while !Task.isCancelled {
                await refresh()
                do { try await Task.sleep(for: .seconds(3)) } catch { break }
            }
        }
    }
    @MainActor private func refresh() async {
        do { let all: [CustomerBroadcast] = try await CustomerFeaturesAPI.shared.request("broadcasts"); campaign = all.first { $0.id == id }; error = nil }
        catch { if !Task.isCancelled { self.error = error.localizedDescription } }
    }
    @MainActor private func action(_ value: String) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { let _: FeatureAccepted = try await CustomerFeaturesAPI.shared.request("broadcast-action", method: "POST", body: ["id": id, "action": value]); await refresh() }
        catch { self.error = error.localizedDescription }
    }
}
