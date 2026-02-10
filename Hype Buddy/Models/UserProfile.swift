//
//  UserProfile.swift
//  Hype Buddy
//
//  SwiftData model for user profile and settings
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var freeUsesRemaining: Int
    var weekStartDate: Date
    var isPremium: Bool
    var selectedMascot: String
    var unlockedMascots: [String]
    var totalHypes: Int
    var totalWins: Int
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        freeUsesRemaining: Int = 5,
        weekStartDate: Date = Date(),
        isPremium: Bool = false,
        selectedMascot: String = "sparky",
        unlockedMascots: [String] = ["sparky"],
        totalHypes: Int = 0,
        totalWins: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.freeUsesRemaining = freeUsesRemaining
        self.weekStartDate = weekStartDate
        self.isPremium = isPremium
        self.selectedMascot = selectedMascot
        self.unlockedMascots = unlockedMascots
        self.totalHypes = totalHypes
        self.totalWins = totalWins
        self.createdAt = createdAt
    }
}

// MARK: - Usage Tracking

extension UserProfile {
    /// Check if the week has reset and update if needed
    func checkAndResetWeeklyUsage() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we're in a new week
        if !calendar.isDate(weekStartDate, equalTo: now, toGranularity: .weekOfYear) {
            freeUsesRemaining = 5
            weekStartDate = now
        }
    }
    
    /// Check if user can get a hype (premium or has free uses)
    var canGetHype: Bool {
        isPremium || freeUsesRemaining > 0
    }
    
    /// Use a free hype (decrements counter)
    func useHype() {
        if !isPremium && freeUsesRemaining > 0 {
            freeUsesRemaining -= 1
        }
        totalHypes += 1
        checkMascotUnlocks()
    }
    
    /// Record a win
    func recordWin() {
        totalWins += 1
    }
    
    /// Check and unlock mascots based on total hypes
    private func checkMascotUnlocks() {
        // Boost unlocks at 10 hypes
        if totalHypes >= 10 && !unlockedMascots.contains("boost") {
            unlockedMascots.append("boost")
        }
        
        // Pep unlocks at 25 hypes
        if totalHypes >= 25 && !unlockedMascots.contains("pep") {
            unlockedMascots.append("pep")
        }
    }
    
    /// Check if a mascot is unlocked
    func isMascotUnlocked(_ mascot: String) -> Bool {
        unlockedMascots.contains(mascot)
    }
    
    /// Get progress toward next mascot unlock
    var nextUnlockProgress: (mascot: String, current: Int, required: Int)? {
        if !unlockedMascots.contains("boost") {
            return ("boost", totalHypes, 10)
        } else if !unlockedMascots.contains("pep") {
            return ("pep", totalHypes, 25)
        }
        return nil
    }
}
