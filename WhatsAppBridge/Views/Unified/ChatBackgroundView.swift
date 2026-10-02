import SwiftUI

struct ChatBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Image("BridgeChatWallpaper")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
