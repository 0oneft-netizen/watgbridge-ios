import SwiftUI

struct WhatsAppCustomerIdentity: Decodable {
    let accountID: String
    let jid: String
    let pushName: String
    let businessName: String
    enum CodingKeys: String, CodingKey { case accountID = "account_id", jid, pushName = "push_name", businessName = "business_name" }
}
@MainActor struct WhatsAppIdentitySection: View {
    let conversation: Conversation
    @State private var value: WhatsAppCustomerIdentity?
    @State private var loading = true
    @State private var scope = UserWorkspace.id
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let value, !value.pushName.isEmpty {
                LabeledContent("השם ב־WhatsApp", value: value.pushName).textSelection(.enabled)
            } else if !loading {
                Text("השם ב־WhatsApp עדיין לא התקבל").font(.caption).foregroundStyle(.secondary)
            }
            if let value, !value.businessName.isEmpty {
                LabeledContent("שם עסק ב־WhatsApp", value: value.businessName).textSelection(.enabled)
            }
        }
        .task(id: conversation.id) {
            loading = true; value = nil
            do {
                let received: WhatsAppCustomerIdentity = try await UltraCompleteAPI.request("features/customer-identity", workspace: scope, query: [
                    .init(name: "account_id", value: conversation.accountID ?? "default"), .init(name: "jid", value: conversation.jid)
                ])
                guard scope == UserWorkspace.id, received.accountID == (conversation.accountID ?? "default"), received.jid == conversation.jid, !Task.isCancelled else { return }
                value = received
            } catch {}
            loading = false
        }
    }
}
