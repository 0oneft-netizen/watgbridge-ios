import SwiftUI
import UIKit

// Native styling adapted from SwiftLogic/WhatsAppClone-Series and Assets (MIT).
enum WhatsAppVisualDesign {
    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
    static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            uiColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
    static let brand = adaptive(0x008C6A, 0x21C063)
    static let accent = adaptive(0x008C6A, 0x21C063)
    static let background = adaptive(0xF2F2F7, 0x101010)
    static let surface = adaptive(0xFFFFFF, 0x171717)
    static let primaryText = adaptive(0x111111, 0xFFFFFF)
    static let secondaryText = adaptive(0x636366, 0xAEAEB2)
    static let mutedText = adaptive(0x8E8E93, 0x98989D)
    static let border = adaptive(0xD1D1D6, 0x38383A)
    static let incoming = surface
    static let outgoing = adaptive(0xD0FDCF, 0x144D37)
    static let outgoingText = adaptive(0x111111, 0xFFFFFF)
    static let bubbleRadius: CGFloat = 16

    static func bubbleShape(fromMe: Bool) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: bubbleRadius,
            bottomLeadingRadius: fromMe ? bubbleRadius : 2,
            bottomTrailingRadius: fromMe ? 2 : bubbleRadius,
            topTrailingRadius: bubbleRadius
        )
    }
}

struct WhatsAppListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(WhatsAppVisualDesign.background)
            .listRowBackground(WhatsAppVisualDesign.surface)
            .tint(WhatsAppVisualDesign.accent)
            .toolbarBackground(WhatsAppVisualDesign.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
