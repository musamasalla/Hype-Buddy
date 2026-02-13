//
//  TextChatView.swift
//  Hype Buddy
//
//  Text-based chat with AI mascot — alternative to voice
//

import SwiftUI
import SwiftData

struct TextChatView: View {
    @State private var viewModel: TextChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    init(
        mascot: Mascot,
        userProfile: UserProfile,
        geminiService: GeminiService,
        voiceService: VoiceService,
        modelContext: ModelContext,
        isPremium: Bool
    ) {
        _viewModel = State(initialValue: TextChatViewModel(
            mascot: mascot,
            userProfile: userProfile,
            geminiService: geminiService,
            voiceService: voiceService,
            modelContext: modelContext,
            isPremium: isPremium
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.Gradients.voiceChat
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerBar
                
                // Chat messages
                chatMessages
                
                // TTS fallback indicator
                if viewModel.voiceService.isUsingFallback && viewModel.readAloud {
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
                }
                
                // Input bar
                inputBar
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Text(viewModel.mascot.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chat with \(viewModel.mascot.name)")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    
                    Text(viewModel.isProcessing ? "Typing..." : "Online")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(viewModel.isProcessing ? viewModel.mascot.color : Theme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Read aloud toggle
            Button {
                viewModel.readAloud.toggle()
                if !viewModel.readAloud {
                    viewModel.stopSpeaking()
                }
            } label: {
                Image(systemName: viewModel.readAloud ? "speaker.wave.2.fill" : "speaker.slash")
                    .font(.system(size: 16))
                    .foregroundStyle(viewModel.readAloud ? viewModel.mascot.color : Theme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.xs)
    }
    
    // MARK: - Chat Messages
    
    private var chatMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    // Welcome message
                    if viewModel.messages.isEmpty {
                        welcomeMessage
                    }
                    
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
                    
                    // Typing indicator
                    if viewModel.isProcessing {
                        HStack {
                            TypingIndicator(color: viewModel.mascot.color)
                            Spacer(minLength: 60)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .id("typing")
                    }
                    
                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.error)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.error.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isProcessing) {
                if viewModel.isProcessing {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Welcome Message
    
    private var welcomeMessage: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(viewModel.mascot.emoji)
                .font(.system(size: 60))
                .padding(.top, Theme.Spacing.xxl)
            
            Text("Hey! I'm \(viewModel.mascot.name) 👋")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("Type anything — tell me what's on your mind,\nwhat you're nervous about, or just say hi!")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(Theme.Typography.body)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .focused($isInputFocused)
            
            // Send button
            Button {
                viewModel.sendMessage()
                isInputFocused = false
                Haptics.impact(style: .light)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        canSend ? viewModel.mascot.color : Theme.Colors.textSecondary.opacity(0.5)
                    )
                    .symbolEffect(.bounce, value: viewModel.messages.count)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
    }
    
    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isProcessing
    }
}
