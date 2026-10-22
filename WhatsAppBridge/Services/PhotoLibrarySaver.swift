import Foundation
import Photos

@MainActor enum PhotoLibrarySaver {
    static func saveImage(at file: URL, workspace: String) async throws {
        guard workspace != "signed-out", workspace == UserWorkspace.id else { throw CancellationError() }
        let prepared = try await Task.detached(priority: .userInitiated) {
            try PhotoExportEncoder.prepare(file: file)
        }.value
        try Task.checkCancellation()
        guard workspace == UserWorkspace.id else { throw CancellationError() }
        let permission = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard permission == .authorized || permission == .limited else {
            throw NSError(domain: "PhotoLibrarySaver", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "יש לאפשר לאפליקציה להוסיף תמונות לגלריה בהגדרות האייפון."])
        }
        try Task.checkCancellation()
        guard workspace == UserWorkspace.id else { throw CancellationError() }
        let filename = "ULTRA-SAP-\(UUID().uuidString).\(prepared.fileExtension)"
        try await PHPhotoLibrary.shared().performChanges {
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = filename
            options.uniformTypeIdentifier = prepared.typeIdentifier
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: prepared.data, options: options)
        }
    }
}
