//
//  CustomTabBar.swift
//  Hype Buddy
//
//  Created for UI Overhaul
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [(image: String, title: String)] = [
        ("house.fill", "Home"),
        ("clock.fill", "History"),
        ("gear", "Settings")
    ]
    
    @Namespace private var namespace
    
    var body: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].image)
                            .font(.system(size: 24, weight: .medium))
                            .symbolEffect(.bounce, value: selectedTab == index)
                        
                        if selectedTab == index {
                            Text(tabs[index].title)
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(selectedTab == index ? Theme.Colors.primary : Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(Theme.Colors.primary.opacity(0.1))
                                    .matchedGeometryEffect(id: "TabBackground", in: namespace)
                            }
                        }
                    )
                }
            }
        }
        .padding(Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(Theme.Colors.secondaryBackground) // Material-like
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
    }
}
