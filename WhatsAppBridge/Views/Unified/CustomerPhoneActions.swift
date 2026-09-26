import SwiftUI
import UIKit

struct CustomerPhoneActions: View {
    let conversation:
        Conversation

    private var phone:
        String {
        CustomerPhoneFormatter
            .digits(
                from:
                    conversation.jid
            )
    }

    var body: some View {
        HStack(spacing: 18) {
            Button {
                UIPasteboard
                    .general
                    .string =
                        "+"
                        + phone
            } label: {
                item(
                    "Copy",
                    "doc.on.doc"
                )
            }

            if let sms =
                URL(
                    string:
                        "sms:"
                        + phone
                ) {

                Link(
                    destination: sms
                ) {
                    item(
                        "SMS",
                        "message"
                    )
                }
            }

            ShareLink(
                item:
                    "+"
                    + phone
            ) {
                item(
                    "Share",
                    "square.and.arrow.up"
                )
            }
        }
        .frame(
            maxWidth:
                .infinity
        )
        .buttonStyle(.plain)
    }

    private func item(
        _ title: String,
        _ icon: String
    ) -> some View {
        VStack(spacing: 5) {
            Image(
                systemName:
                    icon
            )
            .font(.title3)

            Text(title)
                .font(
                    .caption
                )
        }
        .frame(
            minWidth: 58
        )
    }
}
