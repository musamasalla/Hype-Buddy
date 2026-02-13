//
//  Theme.swift
//  Hype Buddy
//
//  Created by Muse Masalla
//  Refactored for UI Overhaul (InvoiceZA Style)
//

import SwiftUI

enum Theme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Brand Colors
        static let primary = Color(hex: "FF6B35") // Sparky Orange
        static let secondary = Color(hex: "4ECDC4") // Boost Teal
        static let tertiary = Color(hex: "9B59B6") // Pep Purple
        static let accent = Color(hex: "FFE66D") // Yellow
        
        // Backgrounds (Adaptive)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        // Text (Adaptive)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // UI Elements
        static let border = Color(.separator)
        static let shadow = Color.black.opacity(0.1)
        static let tint = Color.blue
        
        // Semantic
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let muted = Color.gray
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Gradients
    struct Gradients {
        static func background(for mascot: Color = Colors.primary) -> LinearGradient {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    mascot.opacity(0.06),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        static let home = LinearGradient(
            colors: [
                Color(.systemBackground),
                Colors.primary.opacity(0.04),
                Colors.secondary.opacity(0.03),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let onboarding = LinearGradient(
            colors: [
                Colors.primary.opacity(0.08),
                Color(.systemBackground),
                Colors.secondary.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let voiceChat = LinearGradient(
            colors: [
                Color(.systemBackground),
                Colors.primary.opacity(0.1),
                Colors.tertiary.opacity(0.06),
                Color.black.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Legacy Compatibility (Mapped to New System)
    // These ensure existing code compiles while we transition
    
    static let backgroundPrimary = Colors.background
    static let backgroundSecondary = Colors.secondaryBackground
    static let backgroundCard = Colors.secondaryBackground
    
    static let sparkyOrange = Colors.primary
    static let boostTeal = Colors.secondary
    static let boostBlue = Colors.secondary
    static let pepPurple = Colors.tertiary
    static let accentYellow = Colors.accent
    
    static let textPrimary = Colors.textPrimary
    static let textSecondary = Colors.textSecondary
    
    static let spacingSmall = Spacing.sm
    static let spacingMedium = Spacing.md
    static let spacingLarge = Spacing.lg
    static let spacingXS = Spacing.xs
    
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let headlineFont = Typography.headline
    static let subheadlineFont = Typography.subheadline
    static let bodyFont = Typography.body
    static let captionFont = Typography.caption
    static let smallFont = Typography.footnote
    
    static let backgroundGradient = Colors.background
}

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
