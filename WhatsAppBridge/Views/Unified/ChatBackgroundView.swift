import SwiftUI

struct ChatBackgroundView: View {
    var body: some View {
        ZStack {
            Color(
                uiColor:
                    .systemBackground
            )

            LinearGradient(
                colors: [
                    ChatDesign.accent
                        .opacity(0.035),
                    Color.clear,
                    Color.secondary
                        .opacity(0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                let spacing: CGFloat = 42
                let dotSize: CGFloat = 1.35

                var y: CGFloat = 16

                while y < size.height {
                    var x: CGFloat = 18

                    while x < size.width {
                        let rect = CGRect(
                            x: x,
                            y: y,
                            width: dotSize,
                            height: dotSize
                        )

                        context.fill(
                            Path(
                                ellipseIn: rect
                            ),
                            with: .color(
                                Color.secondary
                                    .opacity(0.055)
                            )
                        )

                        x += spacing
                    }

                    y += spacing
                }
            }
        }
        .ignoresSafeArea()
    }
}
