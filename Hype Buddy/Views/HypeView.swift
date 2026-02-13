//
//  HypeView.swift
//  Hype Buddy
//
//  Voice playback screen with animated mascot, glow rings, and typewriter text
//

import SwiftUI
import SwiftData

struct HypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: HypeSession
    let mascot: Mascot
    @Bindable var subscriptionManager: SubscriptionManager
    
    @State private var voiceService = VoiceService()
    @State private var isPlaying = false
    @State private var hasPlayed = false
    @State private var showWinLog = false
    @State private var pulseAnimation = false
    @State private var revealedText = ""
    @State private var typewriterTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Gradient background
            Theme.Gradients.background(for: mascot.color)
                .ignoresSafeArea()
            
            // Subtle particles
            FloatingParticlesView(
                emojis: [mascot.emoji, "🔥", "✨"],
                count: 6
            )
            .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.lg) {
                Spacer()
                
                // Animated Mascot with glow
                animatedMascot
                
                // Hype Text (typewriter)
                hypeTextSection
                
                Spacer()
                
                // Controls
                controlButtons
                
                // Log Outcome Button
                if hasPlayed {
                    logOutcomeButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    typewriterTask?.cancel()
                    voiceService.stopSpeaking()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showWinLog) {
            WinLogView(session: session)
        }
        .onAppear {
            voiceService.setMascot(mascot)
            playHype()
        }
        .onDisappear {
            typewriterTask?.cancel()
            voiceService.stopSpeaking()
        }
        .onChange(of: voiceService.isSpeaking) { _, newValue in
            isPlaying = newValue
        }
    }
    
    // MARK: - Animated Mascot
    
    private var animatedMascot: some View {
        ZStack {
            // Glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [mascot.color.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(pulseAnimation ? 1.15 : 0.95)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // Pulse rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(mascot.color.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: CGFloat(160 + index * 40), height: CGFloat(160 + index * 40))
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: pulseAnimation
                    )
            }
            
            // Main mascot circle
            Circle()
                .fill(mascot.color.opacity(0.2))
                .frame(width: 160, height: 160)
                .overlay(
                    Circle()
                        .stroke(mascot.color, lineWidth: 3)
                )
                .shadow(color: mascot.color.opacity(0.5), radius: 20)
            
            // Mascot emoji
            Text(mascot.emoji)
                .font(.system(size: 80))
                .scaleEffect(isPlaying ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isPlaying)
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    // MARK: - Hype Text (Typewriter)
    
    private var hypeTextSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(session.scenario)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            
            ScrollView {
                Text(revealedText)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .contentTransition(.numericText())
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 200)
        }
        .padding(Theme.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Controls
    
    private var controlButtons: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Button {
                playHype()
            } label: {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text("Replay")
                        .font(Theme.Typography.footnote)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 80)
            }
            .disabled(isPlaying)
            
            Button {
                if isPlaying {
                    voiceService.stopSpeaking()
                } else {
                    playHype()
                }
            } label: {
                ZStack {
                    // Glow behind button
                    Circle()
                        .fill(mascot.color.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .blur(radius: 10)
                    
                    Circle()
                        .fill(mascot.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: mascot.color.opacity(0.5), radius: 10)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(.white)
                }
            }
            
            Button {
                voiceService.stopSpeaking()
            } label: {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                    Text("Stop")
                        .font(Theme.Typography.footnote)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 80)
            }
            .disabled(!isPlaying)
        }
    }
    
    // MARK: - Log Outcome
    
    private var logOutcomeButton: some View {
        CustomButton(
            title: "How'd it go?",
            icon: "checkmark.circle.fill",
            style: .threeDimensional(color: mascot.color)
        ) {
            showWinLog = true
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
    }
    
    // MARK: - Logic
    
    private func playHype() {
        hasPlayed = true
        voiceService.speak(session.sparkyResponse)
        startTypewriter()
    }
    
    private func startTypewriter() {
        typewriterTask?.cancel()
        revealedText = ""
        let fullText = session.sparkyResponse
        
        typewriterTask = Task {
            for i in fullText.indices {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(25))
                await MainActor.run {
                    revealedText = String(fullText[...i])
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HypeView(
            session: HypeSession(
                scenario: "Big Presentation",
                userInput: "Presenting to executives",
                sparkyResponse: "Let's GO! You've prepared for this moment. Remember that interview you CRUSHED last week? Same energy! Walk in there like you OWN the room. They're lucky to hear what you have to say. Now go CRUSH IT! 🔥"
            ),
            mascot: .sparky,
            subscriptionManager: SubscriptionManager()
        )
    }
}
