import SwiftUI

struct ChatLoadOverlay: View {
    let state:
        ChatLoadState

    let retry:
        () -> Void

    var body: some View {
        switch state {
        case .idle,
             .loaded:
            EmptyView()

        case .loading:
            ProgressView()
                .padding(12)
                .background(
                    .regularMaterial,
                    in: Capsule()
                )

        case .failed:
            Button(
                action: retry
            ) {
                Label(
                    "Reload messages",
                    systemImage:
                        "arrow.clockwise"
                )
                .font(
                    .caption.bold()
                )
                .padding(
                    .horizontal,
                    12
                )
                .padding(
                    .vertical,
                    8
                )
                .background(
                    .regularMaterial,
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
    }
}
