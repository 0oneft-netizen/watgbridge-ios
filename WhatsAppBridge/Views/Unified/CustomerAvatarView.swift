import SwiftUI

struct CustomerAvatarView: View {
    let jid: String
    var accountID: String? = nil
    var size: CGFloat = 42
    @State private var image: UIImage?
    @Environment(\.scenePhase) private var scenePhase
    private var identity: String { UserWorkspace.id + "|" + (accountID ?? "default") + "|" + jid }
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Color.secondary.opacity(0.12)
                    Image(systemName: "person.fill").font(.system(size: size * 0.42)).foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size).clipShape(Circle()).contentShape(Circle())
        .task(id: identity + "|" + String(describing: scenePhase)) {
            image = nil
            guard scenePhase == .active else { return }
            let token = identity
            // Refresh while visible, retry transient busy/offline failures.
            while !Task.isCancelled {
                if let loaded = await CustomerAvatarService.shared.image(jid: jid, accountID: accountID), token == identity, !Task.isCancelled { image = loaded }
                do { try await Task.sleep(for: .seconds(image == nil ? 15 : 300)) } catch { return }
            }
        }
    }
}
