import SwiftUI

struct LiveSessionRouteBadge: View {
    let accountID: String?

    @ObservedObject
    private var directory =
        SessionDirectory.shared

    var body: some View {
        SessionRouteBadge(
            name: directory.name(
                for: accountID
            )
        )
    }
}
