import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeView: View {
    let value: String

    private let context = CIContext()

    var body: some View {
        Group {
            if let image = makeImage() {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))

                    Text("Unable to render QR")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: 270, height: 270)
        .padding(18)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 12,
            y: 4
        )
    }

    private func makeImage() -> UIImage? {
        guard
            !value.isEmpty,
            let data = value.data(using: .utf8)
        else {
            return nil
        }

        let filter =
            CIFilter.qrCodeGenerator()

        filter.message = data

        // L gives more room for the relatively
        // large WhatsApp pairing payload.
        filter.correctionLevel = "L"

        guard let output =
            filter.outputImage
        else {
            return nil
        }

        let transformed =
            output.transformed(
                by: CGAffineTransform(
                    scaleX: 10,
                    y: 10
                )
            )

        guard let cgImage =
            context.createCGImage(
                transformed,
                from: transformed.extent
            )
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
