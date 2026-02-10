//
//  CustomCard.swift
//  Hype Buddy
//
//  Created for UI Overhaul
//

import SwiftUI

struct CustomCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let backgroundColor: Color
    
    init(
        padding: CGFloat = Theme.Spacing.md,
        backgroundColor: Color = Theme.Colors.secondaryBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
