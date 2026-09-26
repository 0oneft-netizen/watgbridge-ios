import SwiftUI
import UIKit

struct MessageActionMenu: View {
    let message:
        Message

    let reply:
        () -> Void

    let forward:
        () -> Void

    let react:
        () -> Void

    let delete:
        () -> Void

    var body: some View {
        Group {
            if MessageActionPolicy
                .mayReply(
                    message
                ) {

                Button(
                    action:
                        reply
                ) {
                    Label(
                        "Reply",
                        systemImage:
                            "arrowshape.turn.up.left"
                    )
                }
            }

            if MessageActionPolicy
                .mayCopy(
                    message
                ) {

                Button {
                    UIPasteboard
                        .general
                        .string =
                            message.text
                } label: {
                    Label(
                        "Copy",
                        systemImage:
                            "doc.on.doc"
                    )
                }
            }

            if MessageActionPolicy
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

            if MessageActionPolicy
                .mayReact(
                    message
                ) {

                Button(
                    action:
                        react
                ) {
                    Label(
                        "React",
                        systemImage:
                            "face.smiling"
                    )
                }
            }

            Divider()

            Button(
                role:
                    .destructive,
                action:
                    delete
            ) {
                Label(
                    "Delete",
                    systemImage:
                        "trash"
                )
            }
        }
    }
}
