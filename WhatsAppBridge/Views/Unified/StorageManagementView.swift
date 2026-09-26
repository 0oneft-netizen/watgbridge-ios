import SwiftUI

struct StorageManagementView: View {
    @State
    private var size =
        "Calculating…"

    @State
    private var cleaning =
        false

    var body: some View {
        List {
            Section(
                "Cache"
            ) {
                LabeledContent(
                    "Current size",
                    value: size
                )

                Button(
                    cleaning
                    ? "Cleaning…"
                    : "Clear old cached media"
                ) {
                    Task {
                        cleaning =
                            true

                        await CacheMaintenance.cleanup()

                        await refresh()

                        cleaning =
                            false
                    }
                }
                .disabled(
                    cleaning
                )
            }

            Section {
                Text(
                    "View Once media is not included in persistent media storage."
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .navigationTitle(
            "Storage"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .task {
            await refresh()
        }
    }

    private func refresh()
        async {

        let bytes =
            await CacheSizeCalculator.bytes()

        size =
            CacheSizeCalculator
                .display(
                    bytes
                )
    }
}
