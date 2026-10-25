import SwiftUI
import Photos

struct ProfilePhotoViewer: View {
    let jid: String
    let accountID: String?
    let customerName: String

    @Environment(\.dismiss)
    private var dismiss

    @State private var loading = true
    @State private var reloadID = 0
    @State private var workspace = UserWorkspace.id
    @State private var image: UIImage?
    @State private var saving = false
    @State private var saved = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if let image {
                    ZoomableMediaImage(
                        image: image
                    )
                    .padding(.vertical, 20)
                } else if !loading {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark").font(.largeTitle)
                        Text("תמונת הפרופיל אינה זמינה כרגע").foregroundStyle(.white)
                        Button("נסה שוב") { reloadID += 1 }
                    }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationTitle(
                customerName
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbarColorScheme(
                .dark,
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {
                    Menu {
                        if let image {
                            ShareLink(
                                item:
                                    Image(
                                        uiImage:
                                            image
                                    ),
                                preview:
                                    SharePreview(
                                        customerName,
                                        image:
                                            Image(
                                                uiImage:
                                                    image
                                            )
                                    )
                            ) {
                                Label(
                                    "Share",
                                    systemImage:
                                        "square.and.arrow.up"
                                )
                            }

                            Button {
                                save(image)
                            } label: {
                                Label(
                                    saved
                                        ? "Saved"
                                        : "Save Photo",
                                    systemImage:
                                        saved
                                        ? "checkmark"
                                        : "square.and.arrow.down"
                                )
                            }
                            .disabled(
                                saving || saved
                            )
                        }
                    } label: {
                        Image(
                            systemName:
                                "ellipsis.circle"
                        )
                    }
                }
            }
            .task(id: "\(workspace)|\(accountID ?? "default")|\(jid)|\(reloadID)") {
                loading = true; image = nil
                let loaded = await CustomerAvatarService.shared.image(jid: jid, accountID: accountID)
                guard workspace == UserWorkspace.id, !Task.isCancelled else { return }
                image = loaded; loading = false
            }
            .alert(
                "Photo",
                isPresented:
                    Binding(
                        get: {
                            errorMessage != nil
                        },
                        set: { value in
                            if !value {
                                errorMessage = nil
                            }
                        }
                    )
            ) {
                Button("OK") {}
            } message: {
                Text(
                    errorMessage ?? ""
                )
            }
        }
    }

    private func save(
        _ image: UIImage
    ) {
        saving = true

        PHPhotoLibrary.requestAuthorization(
            for: .addOnly
        ) { status in
            guard
                status == .authorized ||
                status == .limited
            else {
                DispatchQueue.main.async {
                    saving = false
                    errorMessage =
                        "Photo access was not granted."
                }
                return
            }

            PHPhotoLibrary.shared()
                .performChanges {
                    PHAssetChangeRequest
                        .creationRequestForAsset(
                            from: image
                        )
                } completionHandler: {
                    success,
                    error in

                    DispatchQueue.main.async {
                        saving = false
                        saved = success

                        if let error {
                            errorMessage =
                                error.localizedDescription
                        }
                    }
                }
        }
    }
}
