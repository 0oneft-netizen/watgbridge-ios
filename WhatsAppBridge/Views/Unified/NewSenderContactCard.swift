import SwiftUI
import UIKit

/// Context for an incoming private conversation that has not been saved in this app.
/// No claim is made about the iPhone address book or unavailable mutual-group data.
@MainActor
struct NewSenderContactCard: View {
    let conversation: Conversation
    let onSave: () -> Void
    let onDetails: () -> Void
    @State private var showBlock = false
    @State private var workspace = UserWorkspace.id

    private var phone: String { ChatIdentity.customerPhone(conversation: conversation) }
    private var name: String { ChatIdentity.customerName(conversation: conversation) }
    private var isCurrentWorkspace: Bool { workspace == UserWorkspace.id && workspace != "signed-out" }

    var body: some View {
        VStack(spacing: 14) {
            CustomerAvatarView(jid: conversation.jid, size: 100)
                .accessibilityLabel("תמונת השולח, כאשר זמינה")
            Text(name).font(.title3.weight(.semibold))
                .multilineTextAlignment(.center).textSelection(.enabled)
            if !phone.isEmpty, phone != name {
                Text(phone).font(.subheadline).foregroundStyle(.secondary)
                    .environment(\.layoutDirection, .leftToRight).textSelection(.enabled)
            }
            Text("לא נשמר באנשי הקשר באפליקציה")
                .font(.subheadline).foregroundStyle(.secondary)
            SessionRouteBadge(name: SessionDirectory.shared.name(for: conversation.accountID ?? "default"))
            Button(action: onDetails) {
                Label("פרטי השולח", systemImage: "info.circle")
                    .font(.subheadline.weight(.semibold))
            }.tint(ChatDesign.accent)
            HStack(spacing: 12) {
                Button(action: onSave) {
                    Label("שמירת איש קשר", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.bordered).tint(ChatDesign.accent)
                Button { showBlock = true } label: {
                    Label("חסימה", systemImage: "nosign")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.bordered).tint(.red)
            }.font(.subheadline.weight(.semibold))
            if !phone.isEmpty {
                Button {
                    guard isCurrentWorkspace else { return }
                    UIPasteboard.general.string = phone
                } label: {
                    Label("העתקת המספר האמיתי", systemImage: "doc.on.doc")
                        .font(.caption)
                }.tint(.secondary)
            }
        }
        .padding(22).frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.vertical, 12)
        .disabled(!isCurrentWorkspace)
        .privacySensitive()
        .sheet(isPresented: $showBlock) {
            NavigationStack { ContactBlockAccountsView(conversation: conversation) }
        }
    }
}
