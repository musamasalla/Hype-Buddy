//
//  CustomCard.swift
//  Hype Buddy
//
//  Glassmorphism card with material background
//

import SwiftUI

struct CustomCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let useGlass: Bool
    let backgroundColor: Color
    
    init(
        padding: CGFloat = Theme.Spacing.md,
        useGlass: Bool = true,
        backgroundColor: Color = Theme.Colors.secondaryBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.useGlass = useGlass
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                if useGlass {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(backgroundColor)
                }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}
