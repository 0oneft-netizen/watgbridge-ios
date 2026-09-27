import SwiftUI

struct ComposerAttachmentMenu: View {
    let onCamera: () -> Void
    let onPhotos: () -> Void
    let onDocument: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            attachmentRow(
                title: "Camera",
                subtitle:
                    "Take a photo or video",
                icon: "camera.fill",
                action: onCamera
            )

            Divider()
                .padding(.leading, 58)

            attachmentRow(
                title: "Photo & Video Library",
                subtitle:
                    "Choose existing media",
                icon:
                    "photo.on.rectangle",
                action: onPhotos
            )

            Divider()
                .padding(.leading, 58)

            attachmentRow(
                title: "Document",
                subtitle:
                    "Choose a file",
                icon: "doc.fill",
                action: onDocument
            )
        }
        .background(
            Color(
                uiColor:
                    .secondarySystemBackground
            ),
            in:
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
        )
    }

    private func attachmentRow(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(
                            AppVisualDesign
                                .accent
                                .opacity(0.12)
                        )

                    Image(
                        systemName: icon
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppVisualDesign.accent
                    )
                }
                .frame(
                    width: 36,
                    height: 36
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(title)
                        .font(
                            .body.weight(
                                .medium
                            )
                        )
                        .foregroundStyle(
                            .primary
                        )

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .caption.weight(
                        .bold
                    )
                )
                .foregroundStyle(
                    Color.secondary
                        .opacity(0.55)
                )
            }
            .padding(
                .horizontal,
                12
            )
            .padding(
                .vertical,
                10
            )
        }
        .buttonStyle(.plain)
    }
}
