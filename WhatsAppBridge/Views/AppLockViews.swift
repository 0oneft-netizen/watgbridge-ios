import SwiftUI

struct AppLockSettingsView: View {
    @ObservedObject private var lock = AppLockStore.shared
    @State private var mode: AppLockMode = .pin
    @State private var current = ""
    @State private var secret = ""
    @State private var confirmation = ""
    @State private var message: String?
    @State private var confirmDisable = false

    var body: some View {
        Form {
            Section {
                LabeledContent("נעילת האפליקציה", value: lock.enabled ? "פעילה" : "כבויה")
                if lock.enabled { entry("הקוד הקיים", text: $current, mode: lock.mode) }
            }
            Section(lock.enabled ? "שינוי הקוד" : "הגדרת קוד") {
                Picker("סוג הקוד", selection: $mode) {
                    ForEach(AppLockMode.allCases) { value in Text(value.title).tag(value) }
                }
                entry("קוד חדש", text: $secret, mode: mode)
                entry("הקלד שוב את הקוד החדש", text: $confirmation, mode: mode)
                Text(mode.hint).font(.footnote).foregroundStyle(.secondary)
                Button(lock.enabled ? "שמור קוד חדש" : "הפעל נעילה") {
                    Task {
                        do {
                            try await lock.configure(mode: mode, secret: secret, current: current)
                            clear(); message = "הקוד נשמר. האפליקציה תינעל כשתעזוב אותה."
                        } catch { message = error.localizedDescription }
                    }
                }
                .disabled(lock.busy || !mode.validate(secret) || secret != confirmation || (lock.enabled && current.isEmpty))
            }
            if lock.enabled {
                Section {
                    Button("נעל עכשיו") { clear(); lock.lockNow() }.disabled(lock.busy)
                    Button("בטל נעילה", role: .destructive) { confirmDisable = true }
                        .disabled(lock.busy || current.isEmpty)
                }
            }
            Section {
                if lock.busy { ProgressView("בודק ושומר…") }
                if let message { Text(message).font(.footnote) }
                Text("שמור את הקוד במקום בטוח. אין שחזור קוד מתוך האפליקציה. הנעילה מגינה על הגישה למסכים; היא אינה מצפינה את הנתונים בשרת ואינה מסתירה תצוגות מקדימות בהתראות.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("נעילת אפליקציה")
        .tint(ChatDesign.accent)
        .onAppear { mode = lock.mode }
        .onChange(of: mode) { _, _ in secret = ""; confirmation = ""; message = nil }
        .onChange(of: lock.foreground) { _, active in if !active { clear() } }
        .onDisappear { clear() }
        .confirmationDialog("לבטל את נעילת האפליקציה?", isPresented: $confirmDisable, titleVisibility: .visible) {
            Button("בטל נעילה", role: .destructive) {
                Task {
                    do { try await lock.disable(current: current); clear(); message = "הנעילה בוטלה." }
                    catch { message = error.localizedDescription }
                }
            }
        }
    }
    private func clear() { current = ""; secret = ""; confirmation = "" }
    private func entry(_ title: String, text: Binding<String>, mode: AppLockMode) -> some View {
        SecureField(title, text: text)
            .keyboardType(mode == .pin ? .numberPad : .default)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .privacySensitive()
    }
}

struct AppUnlockView: View {
    @ObservedObject private var lock = AppLockStore.shared
    @State private var secret = ""
    @State private var message: String?
    var body: some View {
        ZStack {
            ChatDesign.chatBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.fill").font(.system(size: 42)).foregroundStyle(ChatDesign.accent)
                Text("WhatsApp Bridge").font(.title2.weight(.semibold))
                Text("האפליקציה נעולה").foregroundStyle(.secondary)
                if lock.foreground {
                    if let error = lock.storageError {
                        Text(error).font(.footnote)
                        Button("נסה שוב") { lock.retryStorage() }
                    } else {
                        SecureField(lock.mode == .pin ? "הקוד המספרי שלך" : "הסיסמה שלך", text: $secret)
                            .keyboardType(lock.mode == .pin ? .numberPad : .default)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder).privacySensitive()
                            .onSubmit { unlock() }
                        Button(action: unlock) {
                            if lock.busy { ProgressView() } else { Text("פתח את האפליקציה").frame(maxWidth: .infinity) }
                        }
                        .buttonStyle(.borderedProminent).disabled(lock.busy || secret.isEmpty)
                        if let message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                    }
                }
            }
            .padding(28).frame(maxWidth: 390)
        }
        .tint(ChatDesign.accent)
        .onChange(of: lock.foreground) { _, _ in secret = ""; message = nil }
        .onDisappear { secret = "" }
    }
    private func unlock() {
        guard !lock.busy else { return }
        let value = secret
        secret = ""
        Task {
            do { try await lock.unlock(value); message = nil }
            catch { message = error.localizedDescription }
        }
    }
}
