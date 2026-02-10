//
//  VoiceChatViewModel.swift
//  Hype Buddy
//
//  Created by Muse Masalla
//

import SwiftUI
import AVFoundation
import SwiftData

@MainActor
@Observable
class VoiceChatViewModel {
    enum State: Equatable {
        case idle
        case listening
        case processing
        case speaking
        case error(String)
    }
    
    var state: State = .idle
    var transcript: String = ""
    var hypeResponse: String = ""
    
    // Dependencies
    private let speechService = SpeechRecognitionService()
    private let geminiService: GeminiService
    private let voiceService: VoiceService
    private let modelContext: ModelContext
    private let isPremium: Bool
    
    // Internal access for View
    let mascot: Mascot
    let userProfile: UserProfile
    
    init(
        geminiService: GeminiService,
        voiceService: VoiceService,
        mascot: Mascot,
        userProfile: UserProfile,
        modelContext: ModelContext,
        isPremium: Bool
    ) {
        self.geminiService = geminiService
        self.voiceService = voiceService
        self.mascot = mascot
        self.userProfile = userProfile
        self.modelContext = modelContext
        self.isPremium = isPremium
    }
    
    func startListening() {
        requestPermissions()
        
        do {
            try speechService.startRecording()
            state = .listening
            Haptics.impact(style: .medium)
        } catch {
            state = .error("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopListeningAndProcess() {
        speechService.stopRecording()
        let userText = speechService.transcript
        
        guard !userText.isEmpty else {
            state = .idle
            return
        }
        
        transcript = userText
        state = .processing
        Haptics.notification(type: .success)
        
        Task {
            await generateAndSpeakHype(for: userText)
        }
    }
    
    private func generateAndSpeakHype(for input: String) async {
        do {
            // Get memory context
            let recentWins = MemoryService.getRecentWins(
                from: modelContext,
                limit: 5,
                isPremium: isPremium
            )
            
            // Generate Hype
            let response = try await geminiService.generateHype(
                scenario: nil,
                customInput: input,
                mascot: mascot,
                recentWins: recentWins
            )
            
            self.hypeResponse = response
            self.state = .speaking
            
            // Speak Hype
            voiceService.setMascot(mascot)
            voiceService.speak(response)
            
            // Note: VoiceService delegate would ideally handle "didFinish" to set state back to idle.
            // For now, we manually reset after a delay or assume VoiceService handles completion state?
            // VoiceService updates its own `isSpeaking` property.
            // We can observe `voiceService.isSpeaking` if we want precise state sync.
            // But strict state machine: stay in .speaking until done?
            // Since VoiceService is Observable, let's just reset to idle when `isSpeaking` becomes false?
            // For simplicity in this fix, we'll let it stay in speaking or reset immediately?
            // "speak" is non-blocking (async inside but returns).
            // Actually, `speak` on VoiceService is synchronous (fire and forget using Task).
            // So we return immediately.
            
            // Wait loop for speaking to finish (simple approach for now)
            // Ideally should use delegate or binding.
            // Let's just set idle manually after a plausible delay or user action?
            // Better: watch voiceService.isSpeaking.
            
            monitorSpeechCompletion()
            
        } catch {
            self.state = .error("Failed to generate hype: \(error.localizedDescription)")
        }
    }
    
    private func monitorSpeechCompletion() {
        // Simple polling for MVP since we are in a Task
        Task {
            // Wait for speaking to start
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            while voiceService.isSpeaking {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            if state == .speaking {
                state = .idle
            }
        }
    }
    
    func cancel() {
        speechService.stopRecording()
        voiceService.stopSpeaking()
        state = .idle
    }
    
    private func requestPermissions() {
        AVAudioApplication.requestRecordPermission { allowed in
            if !allowed {
                Task { @MainActor in
                    self.state = .error("Microphone permission denied")
                }
            }
        }
    }
}
