import Foundation

enum UserWorkspace {
    static var id = "test"
    static let baseURL = URL(string: "https://unit.invalid/u/test")!
}
@main struct ContactUpgradeContracts {
    @MainActor static func main() async throws {
        let unknown = Data("{\"message_id\":\"x\",\"account_id\":\"a\",\"chat_jid\":\"1@s.whatsapp.net\",\"from_me\":true,\"created_at\":100,\"sent_confirmed_at\":null,\"delivered_at\":null,\"read_at\":null,\"state\":\"read\",\"is_group\":false}".utf8)
        let info = try JSONDecoder().decode(ContactMessageInfo.self, from: unknown)
        precondition(info.state == "read" && info.deliveredAt == nil && info.readAt == nil && info.sentConfirmedAt == nil)
        precondition(ContactMessageInfo.date(nil) == nil && ContactMessageInfo.date(0) == nil)
        precondition(ContactMessageInfo.date(1_700_000_000)?.timeIntervalSince1970 == ContactMessageInfo.date(1_700_000_000_000)?.timeIntervalSince1970)
        let plan = try JSONDecoder().decode(ContactBlockPlan.self, from: Data("{\"customer_jid\":\"972501234567@s.whatsapp.net\",\"targets\":[{\"account_id\":\"a\",\"name\":\"Sales\",\"phone\":\"111\"},{\"account_id\":\"b\",\"name\":\"Support\",\"phone\":\"222\"}]}".utf8))
        precondition(plan.phone == "972501234567" && Set(plan.targets.map(\.id)).count == 2)
        let confirmation = try JSONDecoder().decode(ContactBlockConfirmation.self, from: Data("{\"account_id\":\"a\",\"confirmed\":true,\"blocked\":true}".utf8))
        precondition(confirmation.matches(account: "a", desired: true))
        precondition(!confirmation.matches(account: "b", desired: true))
        precondition(!confirmation.matches(account: "a", desired: false))
        let source = try JSONDecoder().decode(Conversation.self, from: Data("{\"account_id\":\"a\",\"jid\":\"1@s.whatsapp.net\",\"name\":\"Customer\",\"last_message\":\"hello\",\"last_message_at\":100,\"unread\":0}".utf8))
        do {
            try await ContactUpgradeAPI.block("b", source: source, desired: true, workspace: "previous-user")
            preconditionFailure("stale user view initiated a request")
        } catch is CancellationError { }
        print("PASS: unknown receipt times stay unknown, seconds/milliseconds normalize, block results require exact account and requested state, stale user view rejected before network access")
    }
}
