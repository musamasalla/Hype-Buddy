//
//  HypeView.swift
//  Hype Buddy
//
//  Voice playback screen with animated mascot
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
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: Theme.spacingLarge) {
                Spacer()
                
                // Animated Mascot
                animatedMascot
                
                // Hype Text
                hypeTextSection
                
                Spacer()
                
                // Controls
                controlButtons
                
                // Log Outcome Button
                if hasPlayed {
                    logOutcomeButton
                }
            }
            .padding(Theme.spacingMedium)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    voiceService.stopSpeaking()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)
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
            voiceService.stopSpeaking()
        }
        .onChange(of: voiceService.isSpeaking) { _, newValue in
            isPlaying = newValue
            if !newValue && hasPlayed {
                // Voice finished
            }
        }
    }
    
    // MARK: - Animated Mascot
    
    private var animatedMascot: some View {
        ZStack {
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
    
    // MARK: - Hype Text
    
    private var hypeTextSection: some View {
        VStack(spacing: Theme.spacingMedium) {
            Text(session.scenario)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, Theme.spacingMedium)
                .padding(.vertical, Theme.spacingXS)
                .background(Theme.backgroundCard)
                .clipShape(Capsule())
            
            ScrollView {
                Text(session.sparkyResponse)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .frame(maxHeight: 200)
        }
        .padding(Theme.spacingLarge)
        .background(Theme.backgroundCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
    }
    
    // MARK: - Controls
    
    private var controlButtons: some View {
        HStack(spacing: Theme.spacingLarge) {
            // Replay button
            Button {
                playHype()
            } label: {
                VStack(spacing: Theme.spacingXS) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text("Replay")
                        .font(Theme.smallFont)
                }
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80)
            }
            .disabled(isPlaying)
            
            // Play/Pause button
            Button {
                if isPlaying {
                    voiceService.stopSpeaking()
                } else {
                    playHype()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(mascot.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: mascot.color.opacity(0.5), radius: 10)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            
            // Stop button
            Button {
                voiceService.stopSpeaking()
            } label: {
                VStack(spacing: Theme.spacingXS) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                    Text("Stop")
                        .font(Theme.smallFont)
                }
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80)
            }
            .disabled(!isPlaying)
        }
    }
    
    // MARK: - Log Outcome
    
    private var logOutcomeButton: some View {
        Button {
            showWinLog = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("How'd it go?")
            }
            .font(Theme.subheadlineFont)
            .foregroundStyle(Theme.accentYellow)
            .padding(.vertical, Theme.spacingSmall)
            .padding(.horizontal, Theme.spacingLarge)
            .background(Theme.accentYellow.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(.bottom, Theme.spacingMedium)
    }
    
    // MARK: - Logic
    
    private func playHype() {
        hasPlayed = true
        voiceService.speak(session.sparkyResponse)
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
