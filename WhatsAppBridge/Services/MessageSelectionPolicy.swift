import Foundation

enum MessageSelectionPolicy {
    static let maximum =
        100

    static func mayAdd(
        currentCount: Int
    ) -> Bool {
        currentCount <
            maximum
    }
}
