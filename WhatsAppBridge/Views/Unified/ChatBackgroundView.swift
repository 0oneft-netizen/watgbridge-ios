import SwiftUI

struct ChatBackgroundView: View {
    var body: some View {
        ZStack {
            Color(
                uiColor:
                    UIColor {
                        traits in

                        if traits.userInterfaceStyle
                            == .dark {
                            return UIColor(
                                red: 0.04,
                                green: 0.06,
                                blue: 0.065,
                                alpha: 1
                            )
                        }

                        return UIColor(
                            red: 0.93,
                            green: 0.91,
                            blue: 0.86,
                            alpha: 1
                        )
                    }
            )

            GeometryReader { proxy in
                Canvas { context, size in
                    let step: CGFloat = 48

                    var x: CGFloat = -20

                    while x < size.width + 20 {
                        var y: CGFloat = -20

                        while y < size.height + 20 {
                            let rect = CGRect(
                                x: x,
                                y: y,
                                width: 18,
                                height: 18
                            )

                            context.opacity = 0.035

                            context.stroke(
                                Path(
                                    ellipseIn: rect
                                ),
                                with: .color(
                                    .secondary
                                ),
                                lineWidth: 1
                            )

                            y += step
                        }

                        x += step
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
