//
//  TextChatViewModel.swift
//  Hype Buddy
//
//  ViewModel for text-based chat with the AI mascot
//

import SwiftUI
import SwiftData
import os.log

private let chatLogger = Logger(subsystem: "com.hypebuddy", category: "TextChat")

// MARK: - Chat Message Model (shared with VoiceChat)

// ChatMessage is defined in VoiceChatViewModel.swift

@MainActor
@Observable
class TextChatViewModel {
    
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isProcessing = false
    var errorMessage: String?
    
    // Dependencies
    private let geminiService: GeminiService
    let voiceService: VoiceService
    private let modelContext: ModelContext
    private let isPremium: Bool
    
    let mascot: Mascot
    let userProfile: UserProfile
    
    // Track first turn for win injection
    private var hasInjectedWins = false
    
    // TTS toggle
    var readAloud = true
    
    init(
        mascot: Mascot,
        userProfile: UserProfile,
        geminiService: GeminiService,
        voiceService: VoiceService,
        modelContext: ModelContext,
        isPremium: Bool
    ) {
        self.mascot = mascot
        self.userProfile = userProfile
        self.geminiService = geminiService
        self.voiceService = voiceService
        self.modelContext = modelContext
        self.isPremium = isPremium
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isProcessing = true
        errorMessage = nil
        
        Haptics.impact(style: .light)
        
        Task {
            await generateResponse(for: text)
        }
    }
    
    private func generateResponse(for input: String) async {
        do {
            // Build conversation history
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
            
            let response = try await geminiService.generateConversationalHype(
                userMessage: input,
                conversationHistory: Array(history),
                mascot: mascot,
                recentWins: recentWins
            )
            
            let aiMessage = ChatMessage(text: response, isUser: false)
            messages.append(aiMessage)
            
            // Speak response if read aloud is enabled
            if readAloud {
                voiceService.setMascot(mascot)
                voiceService.speak(response)
            }
            
            isProcessing = false
            chatLogger.debug("Text chat response generated")
            
        } catch {
            chatLogger.error("Text chat error: \(error.localizedDescription)")
            errorMessage = "Failed to get response. Try again."
            isProcessing = false
        }
    }
    
    func stopSpeaking() {
        voiceService.stopSpeaking()
    }
}
