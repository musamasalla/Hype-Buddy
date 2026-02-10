//
//  VoiceChatView.swift
//  Hype Buddy
//
//  Created by Muse Masalla
//

import SwiftUI
import SwiftData

struct VoiceChatView: View {
    @State private var viewModel: VoiceChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(
        mascot: Mascot,
        userProfile: UserProfile,
        geminiService: GeminiService,
        voiceService: VoiceService,
        modelContext: ModelContext,
        isPremium: Bool
    ) {
        _viewModel = State(initialValue: VoiceChatViewModel(
            geminiService: geminiService,
            voiceService: voiceService,
            mascot: mascot,
            userProfile: userProfile,
            modelContext: modelContext,
            isPremium: isPremium
        ))
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Mascot & Visualizer
                ZStack {
                    if viewModel.state == .listening {
                        PulsingCircle(color: Theme.Colors.accent)
                    } else if viewModel.state == .speaking {
                        PulsingCircle(color: viewModel.mascot.color)
                    }
                    
                    Image(viewModel.mascot.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .shadow(color: Theme.Colors.shadow, radius: 20, x: 0, y: 10)
                }
                
                // Transcript Area
                ScrollView {
                    Text(displayText)
                        .font(Theme.Typography.title2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding()
                }
                .frame(maxHeight: 150)
                
                Spacer()
                
                // Controls
                VStack(spacing: Theme.Spacing.lg) {
                    if case .error(let message) = viewModel.state {
                        Text(message)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.error)
                    }
                    
                    CustomButton(
                        title: viewModel.state == .listening ? "Listening..." : "Hold to Talk",
                        icon: viewModel.state == .listening ? "mic.fill" : "mic",
                        style: .threeDimensional(color: viewModel.mascot.color),
                        isLoading: viewModel.state == .processing
                    ) {
                        // Action handled by LongPressGesture below
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if viewModel.state == .idle {
                                    viewModel.startListening()
                                }
                            }
                            .onEnded { _ in
                                viewModel.stopListeningAndProcess()
                            }
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }
    
    private var displayText: String {
        switch viewModel.state {
        case .idle:
            return "Press and hold to talk to \(viewModel.mascot.name)!"
        case .listening:
            return viewModel.transcript.isEmpty ? "Listening..." : viewModel.transcript
        case .processing:
            return "Thinking..."
        case .speaking:
            return viewModel.hypeResponse
        case .error:
            return "Oops!"
        }
    }
}

// Simple pulsing animation
struct PulsingCircle: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: 250, height: 250)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    opacity = 0.2
                }
            }
    }
}
