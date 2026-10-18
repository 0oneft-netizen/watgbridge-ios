import Foundation
import SwiftUI

struct CustomerWelcomeSettings: Codable {
    var enabled = false
    var text = ""
}
struct CustomerWelcomeJob: Decodable, Identifiable {
    let id: Int64
    let accountID: String
    let jid: String
    let state: String
    let messageID: String
    let lastError: String
    let createdAt: Int64
    enum CodingKeys: String, CodingKey {
        case id, jid, state
        case accountID = "account_id", messageID = "message_id"
        case lastError = "last_error", createdAt = "created_at"
    }
}

@MainActor
struct CustomerWelcomeSettingsView: View {
    @State private var settings = CustomerWelcomeSettings()
    @State private var jobs: [CustomerWelcomeJob] = []
    @State private var loaded = false
    @State private var busy = false
    @State private var feedback: String?
    @State private var scope = UserWorkspace.id
    @ObservedObject private var sessions = SessionDirectory.shared

    var body: some View {
        Form {
            configurationSection
            explanationSection
            historySection
        }
        .navigationTitle("הודעת פתיחה אוטומטית")
        .task { await load() }
        .refreshable { await load() }
    }
    private var configurationSection: some View {
        Section("ההודעה שלך") {
            Toggle("שליחה אוטומטית ללקוח חדש", isOn: $settings.enabled)
            TextEditor(text: $settings.text)
                .frame(minHeight: 140)
                .accessibilityLabel("נוסח הודעת הפתיחה")
            Text("אפשר לשלב {name} לשם הלקוח ו־{phone} למספר המזוהה שלו.")
                .font(.caption).foregroundStyle(.secondary)
            Button("שמור הגדרות") { Task { await save() } }
                .disabled(!loaded || busy || (settings.enabled && settings.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            if busy { ProgressView() }
            if let feedback { Text(feedback).font(.footnote).foregroundStyle(.secondary) }
        }
        .disabled(!loaded || busy)
    }
    private var explanationSection: some View {
        Section("מתי נשלחת ההודעה?") {
            Text("פעם אחת, בעקבות ההודעה הראשונה שהלקוח שולח בצ׳אט חדש באותו חשבון WhatsApp. נבדק שאין הודעות קודמות, כולל היסטוריה שנשמרה או נמחקה מהתצוגה.")
            Text("ההפעלה חלה על הודעות חדשות בלבד. פתיחת צ׳אט, שחזור היסטוריה או חיבור סשן מחדש לא שולחים הודעה. אם כבר ענית, הודעת הפתיחה ממתינה ומדולגת לפני השליחה.")
            Text("זהו נוסח קבוע שלך, ללא OpenAI. הפעלתו משהה את מענה ה־AI ללקוחות חדשים כדי שלא יישלחו שתי תשובות. לקוח חסום או מוחרג אינו מקבל את ההודעה.")
            Text("השינוי מופעל רק אחרי לחיצה על שמור. יש צורך בסשן מחובר; הודעה שלא אושרה אינה נשלחת שוב אוטומטית.")
        }
        .font(.footnote).foregroundStyle(.secondary)
    }
    private var historySection: some View {
        Section("מעקב אחרי הודעות פתיחה") {
            Button("רענן מעקב") { Task { await loadJobs() } }.disabled(busy)
            if jobs.isEmpty { Text("הודעות פתיחה חדשות יופיעו כאן לאחר הפעלת הכלל.").foregroundStyle(.secondary) }
            ForEach(jobs) { job in
                VStack(alignment: .leading, spacing: 5) {
                    Text(job.jid).font(.subheadline)
                    Text(sessions.name(for: job.accountID)).font(.caption).foregroundStyle(.secondary)
                    Text(statusLabel(job.state)).font(.caption)
                    if !job.lastError.isEmpty { Text(job.lastError).font(.caption2).foregroundStyle(.secondary) }
                    Text(Date(timeIntervalSince1970: Double(job.createdAt)).formatted()).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
    private func statusLabel(_ state: String) -> String {
        switch state {
        case "pending": return "ממתינה לשליחה"
        case "sending": return "נשלחת"
        case "sent": return "השליחה אושרה"
        case "skipped": return "דולגה"
        case "cancelled": return "בוטלה"
        case "expired": return "חלון השליחה הסתיים"
        case "uncertain": return "השליחה לא אושרה — לא תישלח שוב אוטומטית"
        default: return "לא נשלחה"
        }
    }
    private func load() async {
        guard !busy, UserWorkspace.id == scope else { return }
        busy = true
        defer { busy = false }
        do {
            let result: CustomerWelcomeSettings = try await CustomerAutomationAPI.shared.request("welcome-settings")
            guard UserWorkspace.id == scope else { return }
            settings = result
            loaded = true
            feedback = nil
            await loadJobs()
        } catch is CancellationError { }
        catch { feedback = "לא ניתן לטעון את ההגדרות. ודא שתיקון השרת מותקן." }
    }
    private func save() async {
        guard !busy, loaded, UserWorkspace.id == scope else { return }
        busy = true
        defer { busy = false }
        do {
            let result: CustomerWelcomeSettings = try await CustomerAutomationAPI.shared.request("welcome-settings", method: "PUT", body: ["enabled": settings.enabled, "text": settings.text])
            guard UserWorkspace.id == scope else { return }
            settings = result
            feedback = settings.enabled ? "נשמר. הודעת הפתיחה פעילה לצ׳אטים חדשים בלבד." : "נשמר. הודעת הפתיחה כבויה."
            await loadJobs()
        } catch is CancellationError { }
        catch { feedback = "השמירה לא אושרה. רענן את ההגדרות לפני ניסיון נוסף." }
    }
    private func loadJobs() async {
        guard UserWorkspace.id == scope else { return }
        do {
            let result: [CustomerWelcomeJob] = try await CustomerAutomationAPI.shared.request("welcome-jobs")
            guard UserWorkspace.id == scope else { return }
            jobs = result
        } catch is CancellationError { }
        catch { feedback = "לא ניתן לרענן את מעקב הודעות הפתיחה." }
    }
}
