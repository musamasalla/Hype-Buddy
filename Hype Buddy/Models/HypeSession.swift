//
//  HypeSession.swift
//  Hype Buddy
//
//  SwiftData model for storing hype sessions
//

import Foundation
import SwiftData

@Model
final class HypeSession {
    var id: UUID
    var scenario: String
    var userInput: String
    var sparkyResponse: String
    var timestamp: Date
    var outcome: String?  // "win", "meh", "tough"
    var outcomeNotes: String?
    var mascotUsed: String
    
    init(
        id: UUID = UUID(),
        scenario: String,
        userInput: String,
        sparkyResponse: String,
        timestamp: Date = Date(),
        outcome: String? = nil,
        outcomeNotes: String? = nil,
        mascotUsed: String = "sparky"
    ) {
        self.id = id
        self.scenario = scenario
        self.userInput = userInput
        self.sparkyResponse = sparkyResponse
        self.timestamp = timestamp
        self.outcome = outcome
        self.outcomeNotes = outcomeNotes
        self.mascotUsed = mascotUsed
    }
}

// MARK: - Convenience Extensions

extension HypeSession {
    var isWin: Bool {
        outcome == "win"
    }
    
    var outcomeEmoji: String {
        switch outcome {
        case "win": return "✅"
        case "meh": return "😐"
        case "tough": return "😤"
        default: return "⏳"
        }
    }
    
    var formattedDate: String {
        timestamp.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Check if outcome is pending (no outcome logged yet)
    var isPending: Bool {
        outcome == nil
    }
}
