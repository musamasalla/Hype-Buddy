//
//  MemoryService.swift
//  Hype Buddy
//
//  Builds context from past wins for personalized hype
//

import Foundation
import SwiftData
import os.log

private let memoryLogger = Logger(subsystem: "com.hypebuddy", category: "Memory")

/// Service that manages memory context for personalized hype
@MainActor
final class MemoryService {
    
    // MARK: - Get Recent Wins
    
    /// Fetches recent wins for memory context
    /// - Parameters:
    ///   - modelContext: The SwiftData model context
    ///   - limit: Maximum number of wins to return
    ///   - isPremium: Whether user is premium (affects limit)
    /// - Returns: Array of recent winning sessions
    static func getRecentWins(
        from modelContext: ModelContext,
        limit: Int = 5,
        isPremium: Bool = false
    ) -> [HypeSession] {
        let effectiveLimit = isPremium ? limit : min(limit, 3)
        
        var descriptor = FetchDescriptor<HypeSession>(
            predicate: #Predicate { session in
                session.outcome == "win"
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = effectiveLimit
        
        do {
            let wins = try modelContext.fetch(descriptor)
            memoryLogger.debug("Fetched \(wins.count) recent wins for memory context")
            return wins
        } catch {
            memoryLogger.error("Failed to fetch recent wins: \(error)")
            return []
        }
    }
    
    // MARK: - Get Pending Outcomes
    
    /// Fetches sessions that need outcome logging
    /// - Parameter modelContext: The SwiftData model context
    /// - Returns: Array of sessions without outcomes
    static func getPendingOutcomes(from modelContext: ModelContext) -> [HypeSession] {
        var descriptor = FetchDescriptor<HypeSession>(
            predicate: #Predicate { session in
                session.outcome == nil
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            memoryLogger.error("Failed to fetch pending outcomes: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    /// Get user's win rate
    static func getWinRate(from modelContext: ModelContext) -> Double {
        do {
            let totalDescriptor = FetchDescriptor<HypeSession>(
                predicate: #Predicate { session in
                    session.outcome != nil
                }
            )
            let total = try modelContext.fetchCount(totalDescriptor)
            
            guard total > 0 else { return 0 }
            
            let winsDescriptor = FetchDescriptor<HypeSession>(
                predicate: #Predicate { session in
                    session.outcome == "win"
                }
            )
            let wins = try modelContext.fetchCount(winsDescriptor)
            
            return Double(wins) / Double(total)
        } catch {
            memoryLogger.error("Failed to calculate win rate: \(error)")
            return 0
        }
    }
    
    /// Get total sessions count
    static func getTotalSessions(from modelContext: ModelContext) -> Int {
        do {
            let descriptor = FetchDescriptor<HypeSession>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            memoryLogger.error("Failed to count sessions: \(error)")
            return 0
        }
    }
    
    // MARK: - Build Memory Context String
    
    /// Builds a memory context string for AI prompts
    static func buildMemoryContextString(from wins: [HypeSession]) -> String {
        guard !wins.isEmpty else { return "" }
        
        return wins.enumerated().map { index, session in
            return "\(index + 1). \(session.scenario) (\(session.timestamp.timeAgoDisplay())): \(session.userInput)"
        }.joined(separator: "\n")
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: self, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "yesterday" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else {
            return "just now"
        }
    }
}
