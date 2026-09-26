import SwiftUI

struct MediaTransferOverlay: View {
    let state:
        MediaTransferState

    var body: some View {
        switch state {
        case .idle,
             .complete:
            EmptyView()

        case .preparing:
            ProgressView()
                .controlSize(
                    .small
                )

        case .transferring(
            let progress
        ):
            if let progress {
                ProgressView(
                    value:
                        progress
                )
                .progressViewStyle(
                    .circular
                )
            } else {
                ProgressView()
                    .controlSize(
                        .small
                    )
            }

        case .failed:
            Image(
                systemName:
                    "exclamationmark.circle.fill"
            )
            .foregroundStyle(
                .red
            )
        }
    }
}
