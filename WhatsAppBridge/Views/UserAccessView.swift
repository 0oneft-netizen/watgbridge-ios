import SwiftUI

struct UserAccessView: View {
    @ObservedObject private var access = UserAccessStore.shared
    @State private var activation = false
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var code = ""
    @State private var failure: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("WATGBRIDGE", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.title2.weight(.semibold))
                    Text("הצ׳אטים, הלקוחות והסשנים של החשבון שלך נשמרים גם בכניסה ממכשיר נוסף.")
                        .foregroundStyle(.secondary)
                }
                Section(activation ? "הפעלת חשבון חדש" : "כניסה לחשבון") {
                    if activation {
                        TextField("קוד הפעלה אישי", text: $code)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    TextField("שם משתמש", text: $username)
                        .textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("סיסמה", text: $password)
                        .textContentType(activation ? .newPassword : .password)
                    if activation {
                        SecureField("אימות סיסמה", text: $confirmation).textContentType(.newPassword)
                        Text("שם משתמש: 3–32 אותיות באנגלית, מספרים או הסימנים . _ -\nסיסמת חשבון: לפחות 12 תווים. קוד נעילת האפליקציה מוגדר בנפרד.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button(activation ? "יצירת החשבון" : "התחברות") {
                        Task {
                            failure = nil
                            if activation && password != confirmation { failure = "הסיסמאות אינן תואמות."; return }
                            do {
                                try await access.signIn(username: username, password: password, code: activation ? code : nil)
                                password = ""; confirmation = ""; code = ""
                            } catch { failure = error.localizedDescription }
                        }
                    }
                    .disabled(access.busy || username.isEmpty || password.isEmpty || (activation && code.isEmpty))
                    if access.busy { ProgressView() }
                }
                if let message = failure ?? access.error {
                    Section { Text(message).foregroundStyle(.red) }
                }
                Section {
                    Button(activation ? "כבר יש לי חשבון — התחברות" : "יש לי קוד הפעלה — חשבון חדש") {
                        activation.toggle(); failure = nil; password = ""; confirmation = ""
                    }
                    Text("לשחזור סיסמה פנה למנהל השירות. קוד הפעלה משמש פעם אחת ואינו מאפס חשבון קיים.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(activation ? "חשבון חדש" : "ברוך הבא")
        }
        .tint(ChatDesign.accent)
    }
}

struct UserAccountView: View {
    @ObservedObject private var access = UserAccessStore.shared
    @State private var confirm = false
    @State private var error: String?
    var body: some View {
        Form {
            Section("החשבון שלי") {
                LabeledContent("שם משתמש", value: access.user?.username ?? "")
                LabeledContent("סוג חשבון", value: access.user?.owner == true ? "Owner" : "משתמש")
                Text("הנתונים נשמרים בשרת ושייכים לחשבון הזה. התנתקות אינה מוחקת צ׳אטים או סשנים.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button("התנתקות", role: .destructive) { confirm = true }.disabled(access.busy)
                if access.busy { ProgressView() }
                if let error { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("החשבון שלי")
        .confirmationDialog("להתנתק מהחשבון?", isPresented: $confirm, titleVisibility: .visible) {
            Button("התנתקות", role: .destructive) {
                Task { do { try await access.signOut() } catch { self.error = error.localizedDescription } }
            }
        }
    }
}
