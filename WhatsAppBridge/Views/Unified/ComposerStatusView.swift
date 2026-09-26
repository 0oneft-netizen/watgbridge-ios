import SwiftUI

struct ComposerStatusView: View {
    let state:
        ComposerSendState

    var body: some View {
        switch state {
        case .ready:
            EmptyView()

        case .sending:
            ProgressView()
                .controlSize(
                    .small
                )

        case .queued:
            Image(
                systemName:
                    "clock"
            )
            .foregroundStyle(
                .secondary
            )

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
