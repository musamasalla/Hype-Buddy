//
//  VoiceChatViewModel.swift
//  Hype Buddy
//
//  Created by Muse Masalla
//

import SwiftUI
import AVFoundation
import SwiftData

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

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
    var messages: [ChatMessage] = []
    
    // Live transcript while user is speaking
    var liveTranscript: String = ""
    
    // Dependencies
    private let speechService = SpeechRecognitionService()
    private let geminiService: GeminiService
    let voiceService: VoiceService
    private let modelContext: ModelContext
    private let isPremium: Bool
    
    // Internal access for View
    let mascot: Mascot
    let userProfile: UserProfile
    
    // Track whether wins have been injected (first turn only)
    private var hasInjectedWins = false
    
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
            liveTranscript = ""
            Haptics.impact(style: .medium)
            
            // Poll for live transcript updates
            monitorLiveTranscript()
        } catch {
            state = .error("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    private func monitorLiveTranscript() {
        Task {
            while state == .listening {
                liveTranscript = speechService.transcript
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }
    }
    
    func stopListeningAndProcess() {
        speechService.stopRecording()
        let userText = speechService.transcript
        
        guard !userText.isEmpty else {
            state = .idle
            liveTranscript = ""
            return
        }
        
        // Add user message to conversation
        let userMessage = ChatMessage(text: userText, isUser: true)
        messages.append(userMessage)
        liveTranscript = ""
        
        state = .processing
        Haptics.notification(type: .success)
        
        Task {
            await generateAndSpeakHype(for: userText)
        }
    }
    
    private func generateAndSpeakHype(for input: String) async {
        do {
            // Build conversation history from messages
            let history = messages.dropLast().map { msg -> (role: String, text: String) in
                (role: msg.isUser ? "user" : "assistant", text: msg.text)
            }
            
            // Only fetch wins on first turn
            let recentWins: [HypeSession]
            if !hasInjectedWins {
                recentWins = MemoryService.getRecentWins(
                    from: modelContext,
                    limit: 5,
                    isPremium: isPremium
                )
                hasInjectedWins = true
            } else {
                recentWins = []
            }
            
            // Generate conversational response
            let response = try await geminiService.generateConversationalHype(
                userMessage: input,
                conversationHistory: Array(history),
                mascot: mascot,
                recentWins: recentWins
            )
            
            // Add AI response to conversation
            let aiMessage = ChatMessage(text: response, isUser: false)
            messages.append(aiMessage)
            
            self.state = .speaking
            
            // Speak response
            voiceService.setMascot(mascot)
            voiceService.speak(response)
            
            monitorSpeechCompletion()
            
        } catch {
            self.state = .error("Failed to generate hype: \(error.localizedDescription)")
        }
    }
    
    private func monitorSpeechCompletion() {
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
        liveTranscript = ""
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
