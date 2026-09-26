import SwiftUI

struct MediaActionBar: View {
    let message:
        Message

    let save:
        () -> Void

    let share:
        () -> Void

    let forward:
        () -> Void

    var body: some View {
        HStack {
            if MediaOperationPolicy
                .maySave(
                    message
                ) {

                Button(
                    action:
                        save
                ) {
                    Label(
                        "Save",
                        systemImage:
                            "square.and.arrow.down"
                    )
                }
            }

            Spacer()

            if MediaOperationPolicy
                .mayShare(
                    message
                ) {

                Button(
                    action:
                        share
                ) {
                    Label(
                        "Share",
                        systemImage:
                            "square.and.arrow.up"
                    )
                }
            }

            Spacer()

            if MediaOperationPolicy
                .mayForward(
                    message
                ) {

                Button(
                    action:
                        forward
                ) {
                    Label(
                        "Forward",
                        systemImage:
                            "arrowshape.turn.up.right"
                    )
                }
            }
        }
        .font(
            .subheadline
                .weight(
                    .semibold
                )
        )
    }
}
