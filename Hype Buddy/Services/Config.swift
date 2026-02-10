//
//  Config.swift
//  Hype Buddy
//
//  App configuration constants
//

import Foundation

enum Config {
    // MARK: - Subscription
    static let premiumMonthlyProductID = "com.musamasalla.hypebuddy.premium.monthly"
    static let premiumYearlyProductID = "com.musamasalla.hypebuddy.premium.yearly"
    
    // MARK: - Free Tier Limits
    static let freeHypesPerWeek = 5
    static let freeHistoryLimit = 10  // Last 10 sessions for free users
    
    // MARK: - Edge TTS Server
    static let edgeTTSServerURL = "https://openai-edge-tts-production-c3c6.up.railway.app"
    static let edgeTTSAPIKey = "luna_tts_key"  // Reusing Luna's TTS server
    
    // MARK: - AI Settings
    // Firebase AI Logic is configured via GoogleService-Info.plist
    static let geminiModel = "gemini-2.5-flash-lite"
    static let maxResponseTokens = 200  // Keep responses short for voice
    
    // MARK: - App Info
    static let appName = "Hype Buddy"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    // MARK: - Support
    static let privacyPolicyURL = "https://musamasalla.github.io/hype-buddy/privacy.html"
    static let termsOfServiceURL = "https://musamasalla.github.io/hype-buddy/terms.html"
    static let supportEmail = "musamasalladev@gmail.com"
    
    // URL versions for views
    static let privacyURL = URL(string: privacyPolicyURL)!
    static let termsURL = URL(string: termsOfServiceURL)!
    static let supportURL = URL(string: "mailto:\(supportEmail)")!
    
    // MARK: - Notification
    static let winLogReminderDelay: TimeInterval = 2 * 60 * 60  // 2 hours after hype
}

// MARK: - Scenarios

enum HypeScenario: String, CaseIterable, Identifiable {
    case presentation = "presentation"
    case interview = "interview"
    case workout = "workout"
    case date = "date"
    case hardConvo = "hard_convo"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .presentation: return "Big Presentation"
        case .interview: return "Job Interview"
        case .workout: return "Tough Workout"
        case .date: return "First Date"
        case .hardConvo: return "Hard Conversation"
        }
    }
    
    var emoji: String {
        switch self {
        case .presentation: return "🎤"
        case .interview: return "💼"
        case .workout: return "💪"
        case .date: return "❤️"
        case .hardConvo: return "💬"
        }
    }
    
    var contextPrompt: String {
        switch self {
        case .presentation:
            return "about to give a presentation or public speaking"
        case .interview:
            return "about to go into a job interview"
        case .workout:
            return "about to do a challenging workout or physical activity"
        case .date:
            return "about to go on a date and feeling nervous"
        case .hardConvo:
            return "about to have a difficult or uncomfortable conversation"
        }
    }
}
