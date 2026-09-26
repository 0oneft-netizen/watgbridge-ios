import SwiftUI

struct ConversationLinksView: View {
    let links: [String]

    var body: some View {
        List {
            if links.isEmpty {
                ContentUnavailableView(
                    "No Links",
                    systemImage: "link"
                )
            }

            ForEach(
                Array(
                    Set(links)
                ).sorted(),
                id: \.self
            ) { value in
                if let url = URL(string: value) {
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            Image(
                                systemName: "link"
                            )

                            Text(value)
                                .lineLimit(2)

                            Spacer()

                            Image(
                                systemName:
                                    "arrow.up.right"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Links")
        .navigationBarTitleDisplayMode(.inline)
    }
}
