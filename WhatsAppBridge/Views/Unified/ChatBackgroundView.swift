import SwiftUI

struct ChatBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        GeometryReader { geometry in
            Image("BridgeChatWallpaper")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(colorScheme == .dark ? Color.black.opacity(0.72) : Color.clear)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
