import SwiftUI

@MainActor
struct ExistingSessionReconnectView: View {
    let account: SessionAccountDTO
    @Environment(\.dismiss) private var dismiss
    @State private var workspace = UserWorkspace.id
    @State private var state = "connecting"
    @State private var qr = ""
    @State private var failure: String?
    @State private var busy = false
    @State private var attempt = 0
    private var phone: String {
        let value = (account.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        return IsraeliPhonePresentation.copyValue(value.hasPrefix("+") ? value : "+" + value)
    }
    private var name: String { (account.displayName?.isEmpty == false ? account.displayName : nil) ?? phone }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: state == "connected" ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                        .font(.system(size: 44)).foregroundStyle(state == "connected" ? Color.green : Color.accentColor)
                    Text(name.isEmpty ? "חשבון WhatsApp" : name).font(.title2.bold())
                    if !phone.isEmpty { Text(phone).font(.title3.monospacedDigit()).environment(\.layoutDirection, .leftToRight) }
                    Text(ExistingSessionReconnectPolicy.explanation(state)).font(.headline).multilineTextAlignment(.center)
                    if !qr.isEmpty {
                        QRCodeView(value: qr).id(qr)
                        Text("יש לסרוק מתוך WhatsApp של המספר שמופיע למעלה: הגדרות ← מכשירים מקושרים ← קישור מכשיר.")
                            .font(.subheadline).multilineTextAlignment(.center)
                    } else if busy && state != "connected" {
                        ProgressView().padding()
                    }
                    Text("החיבור מתחדש באותו חשבון. הצ׳אטים וההיסטוריה הקיימים נשארים משויכים אליו.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if let failure {
                        Text(failure).font(.subheadline).foregroundStyle(.orange).multilineTextAlignment(.center)
                    }
                    if state == "connected" {
                        Button("סיום") { dismiss() }.buttonStyle(.borderedProminent)
                    } else if !busy && state != "identity_mismatch" && state != "archived" {
                        Button("נסה לחבר מחדש") { attempt += 1 }.buttonStyle(.borderedProminent)
                    }
                }.padding(24)
            }
            .navigationTitle("חיבור מחדש לאותו חשבון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("סגירה") { dismiss() } } }
            .task(id: attempt) { await reconnect() }
            .onDisappear { qr = "" }
        }
    }
    private func reconnect() async {
        guard ExistingSessionReconnectPolicy.managedID(account.id), workspace == UserWorkspace.id, workspace != "signed-out" else { return }
        busy = true; failure = nil; qr = ""; state = "connecting"
        defer { busy = false }
        let deadline = Date().addingTimeInterval(180)
        var first = true
        do {
            while !Task.isCancelled && Date() < deadline {
                let restart = first; first = false
                let result = try await APIClient.shared.existingSessionReconnect(accountID: account.id, restart: restart, workspace: workspace)
                guard UserWorkspace.id == workspace, !Task.isCancelled else { return }
                state = result.status.lowercased(); qr = result.qr
                if state == "connected" {
                    qr = ""; await SessionDirectory.shared.refresh(); return
                }
                if ["identity_mismatch", "archived", "qr_timeout", "client_outdated", "error"].contains(state) {
                    qr = ""
                    failure = result.error.isEmpty ? ExistingSessionReconnectPolicy.explanation(state) : String(result.error.prefix(300))
                    return
                }
                try await Task.sleep(for: .seconds(2))
            }
            if !Task.isCancelled { failure = "החיבור עדיין לא הושלם. אפשר לנסות שוב; לא נוצר חשבון נוסף." }
        } catch is CancellationError { }
          catch { if UserWorkspace.id == workspace && !Task.isCancelled { failure = error.localizedDescription } }
    }
}
