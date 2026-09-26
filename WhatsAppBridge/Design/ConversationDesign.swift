import SwiftUI

enum ConversationDesign {
    static let bubbleRadius: CGFloat = 17
    static let bubbleTailRadius: CGFloat = 5

    static let messageSpacing: CGFloat = 2
    static let groupSpacing: CGFloat = 8

    static let horizontalInset: CGFloat = 10
    static let bubbleHorizontalPadding: CGFloat = 11
    static let bubbleVerticalPadding: CGFloat = 7

    static let maximumBubbleWidth: CGFloat = 310

    static func bubbleColor(
        fromMe: Bool
    ) -> Color {
        fromMe
            ? Color(
                red: 0.84,
                green: 0.96,
                blue: 0.79
            )
            : Color(
                uiColor:
                    .secondarySystemBackground
            )
    }
}
