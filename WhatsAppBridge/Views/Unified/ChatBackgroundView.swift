import SwiftUI

struct ChatBackgroundView: View {
    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        ZStack {
            (
                colorScheme == .dark
                ? AppVisualDesign.chatBackgroundDark
                : AppVisualDesign.chatBackgroundLight
            )
            .ignoresSafeArea()

            Canvas { context, size in
                let step: CGFloat = 58

                var x: CGFloat = -20
                while x < size.width + step {
                    var y: CGFloat = -20

                    while y < size.height + step {
                        let rect = CGRect(
                            x: x,
                            y: y,
                            width: 18,
                            height: 18
                        )

                        context.stroke(
                            Path(
                                roundedRect: rect,
                                cornerRadius: 6
                            ),
                            with: .color(
                                Color.secondary.opacity(
                                    colorScheme == .dark
                                    ? 0.025
                                    : 0.035
                                )
                            ),
                            lineWidth: 0.7
                        )

                        y += step
                    }

                    x += step
                }
            }
            .allowsHitTesting(false)
        }
    }
}
