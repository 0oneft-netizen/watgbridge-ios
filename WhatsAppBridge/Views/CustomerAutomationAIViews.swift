import SwiftUI

// Stale-audience settings remain independent of the local agent and broadcasts.
struct CustomerAutomationSettingsView: View {
    @State private var settings = CustomerAutomationSettings()
    @State private var loaded = false
    @State private var busy = false
    @State private var errorText: String?
    var body: some View {
        Form {
            Section("רשימת חוסר פעילות") {
                Toggle("רשימה אוטומטית", isOn: $settings.staleEnabled)
                Stepper("\(settings.staleHours) שעות", value: $settings.staleHours, in: 1...8760)
                TextField("שעות", value: $settings.staleHours, format: .number).keyboardType(.numberPad)
                Text("הרשימה מתעדכנת בשרת ואינה שולחת הודעות בעצמה.").font(.footnote)
            }
            Section {
                NavigationLink("ה־AI שלי · ללא מפתח חיצוני") { LocalAgentCenter() }
                Button("שמור") { Task { await save() } }.disabled(!loaded || busy)
                if let errorText { Text(errorText).foregroundStyle(.secondary) }
            }
        }.navigationTitle("חוסר פעילות").disabled(busy).task { await load() }
    }
    @MainActor private func load() async {
        do { let v: CustomerAutomationConfiguration = try await CustomerAutomationAPI.shared.request("settings"); settings = v.settings; settings.aiEnabled = false; loaded = true }
        catch { errorText = error.localizedDescription }
    }
    @MainActor private func save() async {
        busy = true; defer { busy = false }; settings.aiEnabled = false
        do { let v = try await CustomerAutomationAPI.shared.save(settings); settings = v.settings; errorText = "נשמר" }
        catch { errorText = error.localizedDescription }
    }
}
// Compatibility for links from older screens. No legacy OpenAI editor remains.
struct CustomerAutomationAIInbox: View { var body: some View { LocalAgentInbox() } }
