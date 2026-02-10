//
//  CustomButton.swift
//  Hype Buddy
//
//  Created for UI Overhaul
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonStyle
    let isDisabled: Bool
    let isLoading: Bool
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case threeDimensional(color: Color) // 3D tactile style
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Theme.Colors.primary
            case .secondary: return Theme.Colors.secondaryBackground
            case .outline: return .clear
            case .threeDimensional(let color): return color
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return Theme.Colors.textPrimary
            case .outline: return Theme.Colors.primary
            case .threeDimensional: return .white
            }
        }
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style.foregroundColor)
                }
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(Theme.Typography.headline)
                }
                
                Text(title)
                    .font(Theme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(backgroundView)
            .foregroundColor(style.foregroundColor)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .buttonStyle(PressTrackingButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled || isLoading)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .threeDimensional(let color):
            ZStack {
                // Depth layer (Shadow/Side)
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.7).shadow(.inner(color: .black.opacity(0.2), radius: 0, x: 0, y: 0)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .offset(y: isPressed ? 0 : 6)
                
                // Top face
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .offset(y: isPressed ? 6 : 0)
            }
            
        case .primary:
            Capsule()
                .fill(style.backgroundColor)
                .shadow(color: style.backgroundColor.opacity(0.4), radius: 8, y: 4)
                
        case .secondary:
            Capsule()
                .fill(style.backgroundColor)
                
        case .outline:
            Capsule()
                .stroke(style.backgroundColor, lineWidth: 2)
        }
    }
}

struct PressTrackingButtonStyle: SwiftUI.ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressed
                }
            }
    }
}
