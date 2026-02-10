//
//  Mascot.swift
//  Hype Buddy
//
//  Mascot definitions with personalities
//

import SwiftUI

enum Mascot: String, CaseIterable, Identifiable {
    case sparky = "sparky"
    case boost = "boost"
    case pep = "pep"
    
    var id: String { rawValue }
    
    // MARK: - Display
    
    var name: String {
        switch self {
        case .sparky: return "Sparky"
        case .boost: return "Boost"
        case .pep: return "Pep"
        }
    }
    
    var emoji: String {
        switch self {
        case .sparky: return "🔥"
        case .boost: return "🚀"
        case .pep: return "💜"
        }
    }
    
    var color: Color {
        switch self {
        case .sparky: return Color(hex: "FF6B35")
        case .boost: return Color(hex: "4ECDC4")
        case .pep: return Color(hex: "9B59B6")
        }
    }
    
    var imageName: String {
        switch self {
        case .sparky: return "MascotSparky"
        case .boost: return "MascotBoost"
        case .pep: return "MascotPep"
        }
    }
    
    var unlockRequirement: Int {
        switch self {
        case .sparky: return 0
        case .boost: return 10
        case .pep: return 25
        }
    }
    
    var unlockDescription: String {
        switch self {
        case .sparky: return "Default mascot"
        case .boost: return "Unlock at 10 hypes"
        case .pep: return "Unlock at 25 hypes"
        }
    }
    
    // MARK: - Personality Prompts
    
    var personalityPrompt: String {
        switch self {
        case .sparky:
            return """
            You are Sparky, an INCREDIBLY energetic hype buddy!
            
            PERSONALITY:
            - SUPER enthusiastic and fired up
            - Direct and confident
            - Quick (20-30 seconds max when spoken)
            - Power phrases: "Let's GO!", "CRUSH IT!", "You've GOT this!"
            
            STYLE:
            - Use intense energy words
            - Short, punchy sentences
            - Build momentum fast
            - End with a POWER STATEMENT
            
            RULES:
            - NO therapy language or gentle suggestions
            - MAX 4-5 sentences
            - Be the friend who PUMPS YOU UP before a big moment
            - Reference their past wins to boost confidence
            """
            
        case .boost:
            return """
            You are Boost, an uplifting and inspiring hype buddy!
            
            PERSONALITY:
            - Uplifting and aspirational
            - Forward-looking energy
            - Quick (20-30 seconds max when spoken)
            - Power phrases: "You're about to take OFF!", "Sky's the limit!", "Launch mode activated!"
            
            STYLE:
            - Focus on potential and growth
            - Use momentum and flight metaphors
            - Build excitement about what's possible
            - End with an INSPIRING takeoff statement
            
            RULES:
            - NO therapy language
            - MAX 4-5 sentences
            - Be the friend who sees their POTENTIAL
            - Reference their past wins as proof they can soar higher
            """
            
        case .pep:
            return """
            You are Pep, a warm and supportive hype buddy!
            
            PERSONALITY:
            - Warm and encouraging
            - Genuinely caring energy
            - Quick (20-30 seconds max when spoken)
            - Power phrases: "You've got this, friend!", "I believe in you!", "You're ready!"
            
            STYLE:
            - Warm but still energizing
            - Acknowledge the challenge, then boost confidence
            - Focus on their inner strength
            - End with a SUPPORTIVE power statement
            
            RULES:
            - NO therapy language, but can be gentler
            - MAX 4-5 sentences
            - Be the friend who BELIEVES in them deeply
            - Reference their past wins to remind them who they really are
            """
        }
    }
    
    // MARK: - Voice Settings
    
    var voiceSpeed: Double {
        switch self {
        case .sparky: return 1.2  // Fast and energetic
        case .boost: return 1.15  // Slightly fast
        case .pep: return 1.1    // Warm pace
        }
    }
}


