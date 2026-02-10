//
//  GeminiService.swift
//  Hype Buddy
//
//  AI Service using Google Gemini for hype generation
//

import Foundation
import FirebaseAI
import os.log

private let aiLogger = Logger(subsystem: "com.hypebuddy", category: "AI")

/// Generates personalized hype using Google Gemini via Firebase AI Logic
@MainActor
final class GeminiService {
    static let shared = GeminiService()
    
    private var model: GenerativeModel?
    
    // MARK: - Initialization
    
    private init() {
        setupGemini()
    }
    
    private func setupGemini() {
        model = FirebaseAI.firebaseAI(backend: .googleAI())
            .generativeModel(
                modelName: Config.geminiModel,
                generationConfig: GenerationConfig(
                    temperature: 0.9,  // High creativity for energetic responses
                    topP: 0.95,
                    topK: 40,
                    maxOutputTokens: Config.maxResponseTokens
                )
            )
    }
    
    // MARK: - Generate Hype
    
    /// Generate a personalized hype message
    /// - Parameters:
    ///   - scenario: The scenario type (e.g., presentation, interview)
    ///   - customInput: Optional custom user input
    ///   - mascot: The mascot to use
    ///   - recentWins: Recent wins for context
    /// - Returns: The hype message
    func generateHype(
        scenario: HypeScenario?,
        customInput: String?,
        mascot: Mascot,
        recentWins: [HypeSession]
    ) async throws -> String {
        guard let model = model else {
            throw GeminiError.modelNotInitialized
        }
        
        // Build the prompt
        let prompt = buildPrompt(
            scenario: scenario,
            customInput: customInput,
            mascot: mascot,
            recentWins: recentWins
        )
        
        aiLogger.debug("Generating hype with \(mascot.name)...")
        
        let response = try await model.generateContent(prompt)
        
        guard let text = response.text, !text.isEmpty else {
            throw GeminiError.emptyResponse
        }
        
        aiLogger.debug("Hype generated successfully")
        return text
    }
    
    // MARK: - Prompt Building
    
    private func buildPrompt(
        scenario: HypeScenario?,
        customInput: String?,
        mascot: Mascot,
        recentWins: [HypeSession]
    ) -> String {
        var prompt = mascot.personalityPrompt
        
        // Add memory context from recent wins
        if !recentWins.isEmpty {
            var winContext = ""
            for session in recentWins {
                let notes = session.outcomeNotes ?? ""
                winContext += "- \(session.scenario): \(session.userInput) (Result: WIN! \(notes))\n"
            }
            
            prompt += """
            
            
            MEMORY - User's Recent Wins (use these to personalize your hype):
            \(winContext)
            Reference these past wins naturally to boost their confidence!
            """
        }
        
        // Add the current request
        prompt += "\n\n---\n\nUser is "
        
        if let scenario = scenario {
            prompt += scenario.contextPrompt
        }
        
        if let customInput = customInput, !customInput.isEmpty {
            if scenario != nil {
                prompt += ". They shared: \"\(customInput)\""
            } else {
                prompt += "facing: \(customInput)"
            }
        }
        
        prompt += "\n\nGive them a quick, powerful hype! (4-5 sentences max, designed to be spoken in 20-30 seconds)"
        
        return prompt
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case modelNotInitialized
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .modelNotInitialized:
            return "AI model not initialized"
        case .emptyResponse:
            return "AI returned an empty response"
        }
    }
}
