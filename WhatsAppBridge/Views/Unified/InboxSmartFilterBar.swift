import SwiftUI

struct InboxSmartFilterBar: View {
    @Binding
    var selection:
        InboxSmartFilter

    var body: some View {
        ScrollView(
            .horizontal,
            showsIndicators:
                false
        ) {
            HStack(spacing: 8) {
                ForEach(
                    InboxSmartFilter
                        .allCases
                ) { filter in

                    Button {
                        selection =
                            filter
                    } label: {
                        Text(
                            filter.title
                        )
                        .font(
                            .subheadline
                                .weight(
                                    .semibold
                                )
                        )
                        .padding(
                            .horizontal,
                            13
                        )
                        .padding(
                            .vertical,
                            7
                        )
                        .background(
                            selection
                                ==
                                filter
                            ?
                            Color.green
                                .opacity(
                                    0.16
                                )
                            :
                            Color.secondary
                                .opacity(
                                    0.08
                                ),
                            in:
                                Capsule()
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }
            .padding(
                .horizontal,
                14
            )
        }
    }
}
