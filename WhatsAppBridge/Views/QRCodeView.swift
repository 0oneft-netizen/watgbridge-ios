import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeView: View {
    let value: String

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Group {
            if let image = makeImage() {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(
            width: 270,
            height: 270
        )
        .padding(18)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    private func makeImage() -> UIImage? {
        guard
            !value.isEmpty,
            let data = value.data(
                using: .isoLatin1
            )
        else {
            return nil
        }

        filter.message = data
        filter.correctionLevel = "M"

        guard
            let output =
                filter.outputImage?
                    .transformed(
                        by: CGAffineTransform(
                            scaleX: 12,
                            y: 12
                        )
                    ),
            let cgImage =
                context.createCGImage(
                    output,
                    from: output.extent
                )
        else {
            return nil
        }

        return UIImage(
            cgImage: cgImage
        )
    }
}
