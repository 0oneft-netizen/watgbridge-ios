import Foundation

struct AppCapabilities {
    let multiAccount = true
    let accountAwareRouting = true
    let mediaCache = true
    let viewOncePersistence = false
    let localFollowUpNotifications = true

    // Must remain false until real push path
    // is implemented and runtime verified.
    let killedAppIncomingPush = false

    // Calls are not production-complete.
    let calls = false
}
