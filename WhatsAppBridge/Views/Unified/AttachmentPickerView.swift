import SwiftUI

struct AttachmentPickerView: View {
    let onCamera: () -> Void
    let onPhotos: () -> Void
    let onDocument: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 38, height: 5)
                .padding(.top, 8)

            Text("Share")
                .font(.headline)

            HStack(spacing: 26) {
                attachment(
                    "Camera",
                    icon: "camera.fill",
                    action: onCamera
                )

                attachment(
                    "Photos",
                    icon: "photo.on.rectangle.angled",
                    action: onPhotos
                )

                attachment(
                    "Document",
                    icon: "doc.fill",
                    action: onDocument
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(190)])
        .presentationDragIndicator(.hidden)
    }

    private func attachment(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            dismiss()
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 58, height: 58)

                    Image(systemName: icon)
                        .font(.title2)
                }

                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
