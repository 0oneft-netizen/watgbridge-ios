import Foundation

enum MessageDeliveryState:
    String,
    Codable
{
    case sending
    case sent
    case delivered
    case read
    case failed
}
