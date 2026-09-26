import SwiftUI

struct ChatDateChip: View {
    let timestamp: Int64

    private var date: Date {
        Date(
            timeIntervalSince1970:
                TimeInterval(timestamp)
        )
    }

    private var text: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        return date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }

    var body: some View {
        Text(text)
            .font(
                .caption2.weight(.semibold)
            )
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                .thinMaterial,
                in: Capsule()
            )
            .padding(.vertical, 7)
    }
}
