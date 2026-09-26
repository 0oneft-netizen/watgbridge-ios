import SwiftUI

enum InboxFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case pinned = "Pinned"
    case archived = "Archived"
}

struct InboxFilterBar: View {
    @Binding var selection: InboxFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxFilter.allCases, id: \.self) { item in
                    Button {
                        selection = item
                    } label: {
                        Text(item.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selection == item
                                ? Color.green.opacity(0.18)
                                : Color.secondary.opacity(0.09),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
