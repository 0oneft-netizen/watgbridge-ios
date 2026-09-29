import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit
import CoreImage

struct CustomerContactActions: View {
    let conversation: Conversation

    private var phone: String {
        ChatIdentity.customerPhone(
            conversation: conversation
        )
    }

    var body: some View {
        HStack(spacing: 26) {
            action(
                "Copy",
                icon: "doc.on.doc"
            ) {
                UIPasteboard.general.string =
                    phone
            }

            ShareLink(
                item: phone
            ) {
                actionLabel(
                    "Share",
                    icon:
                        "square.and.arrow.up"
                )
            }

            NavigationLink {
                CustomerQRCodeView(
                    value: phone
                )
            } label: {
                actionLabel(
                    "QR",
                    icon: "qrcode"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func action(
        _ title: String,
        icon: String,
        perform:
            @escaping () -> Void
    ) -> some View {
        Button(
            action: perform
        ) {
            actionLabel(
                title,
                icon: icon
            )
        }
        .buttonStyle(.plain)
    }

    private func actionLabel(
        _ title: String,
        icon: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .frame(
                    width: 48,
                    height: 48
                )
                .background(
                    Color.green
                        .opacity(0.12),
                    in: Circle()
                )

            Text(title)
                .font(.caption)
        }
    }
}

struct CustomerQRCodeView: View {
    let value: String

    private var image: UIImage? {
        let filter =
            CIFilter.qrCodeGenerator()

        filter.message =
            Data(value.utf8)

        let context = CIContext()

        guard
            let output =
                filter.outputImage?
                    .transformed(
                        by:
                            CGAffineTransform(
                                scaleX: 10,
                                y: 10
                            )
                    ),
            let cg =
                context.createCGImage(
                    output,
                    from:
                        output.extent
                )
        else {
            return nil
        }

        return UIImage(cgImage: cg)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: 280
                    )
            }

            Text(value)
                .font(.headline)
                .textSelection(.enabled)

            Spacer()
        }
        .padding()
        .navigationTitle("Contact QR")
        .navigationBarTitleDisplayMode(.inline)
    }
}
