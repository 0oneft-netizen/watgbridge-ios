import Foundation

// Test-only network dependencies. The production Codable models and API wrapper are compiled unchanged.
enum UserWorkspace { static let id = "owner" }
final class APIClient {
    static let shared = APIClient()
    var baseURL: URL { URL(string: "https://example.invalid/u/owner")! }
}
@main
struct CustomerAutomationContracts {
    static func read<T: Decodable>(_ name: String, as: T.Type) throws -> T {
        let path = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent(name)
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: path))
    }
    static func main() throws {
        let config = try read("automation-settings.json", as: CustomerAutomationConfiguration.self)
        precondition(!config.keyReady && !config.settings.aiEnabled && config.settings.staleHours == 168)
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(config.settings)) as! [String: Any]
        precondition(body["ai_enabled"] as? Bool == false && body["daily_limit"] as? Int == 50)
        precondition(body["baseline_id"] == nil && body["token"] == nil, "Private server fields must not be sent from the app")
        let audience = try read("automation-recipients.json", as: [AutomationAudienceMember].self)
        precondition(audience.count == 1 && audience[0].id == "a|1@s.whatsapp.net")
        let campaigns = try read("automation-campaigns.json", as: [AutomationCampaignRecord].self)
        precondition(campaigns.count == 1 && campaigns[0].state == "draft" && campaigns[0].total == 1)
        precondition(campaigns[0].items.count == 1 && !campaigns[0].hasMore && campaigns[0].nextItemID > 0)
        let jobs = try read("automation-ai-jobs.json", as: [AutomationAIReply].self)
        precondition(jobs.count == 1 && jobs[0].accountID == "a" && jobs[0].state == "pending")
        print("PASS: actual Go JSON contracts decode into Swift settings, recipient, campaign, pagination and AI models")
    }
}
