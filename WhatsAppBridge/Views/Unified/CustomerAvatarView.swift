import SwiftUI

struct CustomerAvatarView: View {
    let jid: String
    var size: CGFloat = 42

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.secondary.opacity(0.12)

                    Image(
                        systemName:
                            "person.fill"
                    )
                    .font(
                        .system(
                            size:
                                size * 0.42
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
        .frame(
            width: size,
            height: size
        )
        .clipShape(Circle())
        .contentShape(Circle())
        .task(id: jid) {
            image =
                await CustomerAvatarService
                    .shared
                    .image(jid: jid)
        }
    }
}
