import SwiftUI

struct QuickRepliesView: View {
    let select: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject
    private var store =
        QuickReplyStore.shared

    @State
    private var search = ""

    var body: some View {
        NavigationStack {
            List(
                store.matching(
                    search
                )
            ) { reply in

                Button {
                    select(
                        reply.text
                    )

                    dismiss()
                } label: {
                    VStack(
                        alignment:
                            .leading,
                        spacing: 5
                    ) {
                        Text(
                            "/"
                            + reply.shortcut
                        )
                        .font(
                            .headline
                        )

                        Text(
                            reply.text
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .lineLimit(3)
                    }
                    .padding(
                        .vertical,
                        3
                    )
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(
                "Quick Replies"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .searchable(
                text: $search,
                prompt:
                    "Search replies"
            )
        }
    }
}
