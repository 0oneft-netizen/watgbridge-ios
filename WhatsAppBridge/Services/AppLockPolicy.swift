import Foundation

enum AppLockMode: String, Codable, CaseIterable, Identifiable {
    case pin, password
    var id: String { rawValue }
    var title: String { self == .pin ? "קוד מספרי" : "קוד עם אותיות, ספרות וסימנים" }
    func validate(_ value: String) -> Bool {
        guard (1...128).contains(value.count), value.utf8.count <= 1024 else { return false }
        if self == .pin {
            return value.count <= 12 && value.utf8.allSatisfy { (48...57).contains($0) }
        }
        return true
    }
    var hint: String { self == .pin ? "1–12 ספרות" : "1–128 תווים: אפשר גם מילה, ספרה אחת או סימן אחד" }
}

enum AppLockTimeout: Int, CaseIterable, Identifiable {
    case immediate = 0, oneMinute = 60, twoMinutes = 120
    case fiveMinutes = 300, fifteenMinutes = 900, oneHour = 3600
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .immediate: return "מיידי"
        case .oneMinute: return "אחרי דקה"
        case .twoMinutes: return "אחרי שתי דקות"
        case .fiveMinutes: return "אחרי 5 דקות"
        case .fifteenMinutes: return "אחרי 15 דקות"
        case .oneHour: return "אחרי שעה"
        }
    }
}

// ContinuousClock includes time spent asleep and is unaffected by wall-clock changes.
// Repeated inactive callbacks must not extend the grace period.
struct AppLockGracePeriod {
    private var leftAt: ContinuousClock.Instant?
    mutating func leave(at now: ContinuousClock.Instant) {
        if leftAt == nil { leftAt = now }
    }
    mutating func returnRequiresLock(at now: ContinuousClock.Instant, timeout: AppLockTimeout) -> Bool {
        defer { leftAt = nil }
        guard let leftAt else { return false }
        return leftAt.duration(to: now) >= .seconds(timeout.rawValue)
    }
    mutating func clear() { leftAt = nil }
}
