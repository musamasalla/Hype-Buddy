//
//  VoiceChatView.swift
//  Hype Buddy
//
//  Immersive voice chat: audio visualizer, chat bubbles, gradient bg
//

import SwiftUI
import SwiftData

struct VoiceChatView: View {
    @State private var viewModel: VoiceChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mascotBreathing = false
    
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
            // Gradient background
            Theme.Gradients.voiceChat
                .ignoresSafeArea()
            
            // Ambient particles
            FloatingParticlesView(
                emojis: [viewModel.mascot.emoji, "✨", "💬"],
                count: 6
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerBar
                
                // Chat transcript (fills available space)
                chatTranscript
                
                // Mascot & Visualizer (compact when messages exist)
                mascotVisualizer
                
                // TTS fallback indicator
                if viewModel.voiceService.isUsingFallback {
                    fallbackIndicator
                }
                
                // Controls
                voiceControls
            }
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Live Chat")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text("with \(viewModel.mascot.name)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            // State indicator pill
            statePill
            
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
    
    // MARK: - State Pill
    
    private var statePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
            
            Text(stateLabel)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Chat Transcript
    
    private var chatTranscript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    // Empty state
                    if viewModel.messages.isEmpty && viewModel.liveTranscript.isEmpty {
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Hold the button to talk")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            
                            Text("\(viewModel.mascot.name) is listening ✨")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.xxl)
                    }
                    
                    // Conversation messages
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            text: message.text,
                            isUser: message.isUser,
                            color: message.isUser ? Theme.Colors.primary : viewModel.mascot.color
                        )
                        .id(message.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                    }
                    
                    // Live transcript (while user is speaking)
                    if !viewModel.liveTranscript.isEmpty {
                        ChatBubble(
                            text: viewModel.liveTranscript,
                            isUser: true,
                            color: Theme.Colors.primary.opacity(0.6)
                        )
                        .id("liveTranscript")
                    }
                    
                    // Processing indicator
                    if viewModel.state == .processing {
                        HStack {
                            TypingIndicator(color: viewModel.mascot.color)
                            Spacer(minLength: 60)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .id("processing")
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.liveTranscript) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("liveTranscript", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Mascot & Visualizer
    
    private var mascotVisualizer: some View {
        ZStack {
            // Audio visualizer rings
            AudioVisualizerView(
                color: visualizerColor,
                isActive: viewModel.state == .listening || viewModel.state == .speaking
            )
            
            // Mascot display
            ZStack {
                Circle()
                    .fill(viewModel.mascot.color.opacity(0.15))
                    .frame(width: mascotSize, height: mascotSize)
                    .overlay(
                        Circle()
                            .stroke(viewModel.mascot.color.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: viewModel.mascot.color.opacity(0.3), radius: 20)
                
                Text(viewModel.mascot.emoji)
                    .font(.system(size: mascotSize * 0.5))
                    .scaleEffect(mascotBreathing ? 1.06 : 0.94)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: mascotBreathing
                    )
            }
            .onAppear { mascotBreathing = true }
            
            // Waveform dots (listening state)
            if viewModel.state == .listening {
                WaveformDotsView(color: Theme.Colors.accent)
                    .offset(y: mascotSize * 0.45)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: viewModel.messages.isEmpty ? 280 : 160)
        .padding(.vertical, Theme.Spacing.sm)
        .animation(.easeInOut(duration: 0.4), value: viewModel.messages.isEmpty)
    }
    
    /// Mascot circle shrinks once conversation starts
    private var mascotSize: CGFloat {
        viewModel.messages.isEmpty ? 160 : 100
    }
    
    // MARK: - Fallback Indicator
    
    private var fallbackIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "speaker.wave.2.circle")
                .foregroundStyle(Theme.Colors.warning)
            Text("Using basic voice — TTS server unavailable")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 4)
        .transition(.opacity)
    }
    
    // MARK: - Voice Controls
    
    private var voiceControls: some View {
        VStack(spacing: Theme.Spacing.md) {
            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.error)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.error.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            CustomButton(
                title: viewModel.state == .listening ? "Listening..." : "Hold to Talk",
                icon: viewModel.state == .listening ? "mic.fill" : "mic",
                style: .threeDimensional(color: viewModel.mascot.color),
                isLoading: viewModel.state == .processing
            ) {
                // Action handled by gesture
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
    
    // MARK: - Helpers
    
    private var stateColor: Color {
        switch viewModel.state {
        case .idle: return Theme.Colors.textSecondary
        case .listening: return Theme.Colors.accent
        case .processing: return Theme.Colors.primary
        case .speaking: return viewModel.mascot.color
        case .error: return Theme.Colors.error
        }
    }
    
    private var stateLabel: String {
        switch viewModel.state {
        case .idle: return "Ready"
        case .listening: return "Listening"
        case .processing: return "Thinking"
        case .speaking: return "Speaking"
        case .error: return "Error"
        }
    }
    
    private var visualizerColor: Color {
        switch viewModel.state {
        case .listening: return Theme.Colors.accent
        case .speaking: return viewModel.mascot.color
        default: return viewModel.mascot.color.opacity(0.3)
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let text: String
    let isUser: Bool
    let color: Color
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(isUser ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    isUser
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(.ultraThinMaterial)
                )
                .clipShape(.rect(
                    cornerRadii: .init(
                        topLeading: 18,
                        bottomLeading: isUser ? 18 : 4,
                        bottomTrailing: isUser ? 4 : 18,
                        topTrailing: 18
                    )
                ))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let color: Color
    @State private var phase = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(y: sin(phase + Double(index) * 0.8) * 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadii: .init(
            topLeading: 18,
            bottomLeading: 4,
            bottomTrailing: 18,
            topTrailing: 18
        )))
        .onAppear {
            withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// Legacy compat — PulsingCircle kept for any other views referencing it
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
