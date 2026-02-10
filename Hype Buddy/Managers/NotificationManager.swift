//
//  NotificationManager.swift
//  Hype Buddy
//
//  Manages local notifications for win logging reminders
//

import Foundation
import UserNotifications
import os.log

private let notificationLogger = Logger(subsystem: "com.hypebuddy", category: "Notifications")

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            notificationLogger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            notificationLogger.error("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Win Log Reminder
    
    /// Schedule a reminder to log the outcome of a hype session
    /// - Parameters:
    ///   - sessionID: The ID of the hype session
    ///   - scenario: The scenario for context in the notification
    func scheduleWinLogReminder(for sessionID: UUID, scenario: String) {
        let content = UNMutableNotificationContent()
        content.title = "How'd it go? 🔥"
        content.body = "You had a \(scenario) moment. Let's log the win!"
        content.sound = .default
        content.userInfo = ["sessionID": sessionID.uuidString]
        
        // Schedule for configured delay (default 2 hours)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Config.winLogReminderDelay,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "winlog_\(sessionID.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                notificationLogger.error("Failed to schedule win log reminder: \(error)")
            } else {
                notificationLogger.info("Win log reminder scheduled for session \(sessionID)")
            }
        }
    }
    
    /// Cancel a pending win log reminder
    func cancelWinLogReminder(for sessionID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["winlog_\(sessionID.uuidString)"]
        )
        notificationLogger.debug("Cancelled win log reminder for session \(sessionID)")
    }
    
    // MARK: - Daily Motivation (Optional)
    
    /// Schedule a daily motivation reminder
    /// - Parameter hour: Hour of day to send (0-23)
    func scheduleDailyMotivation(at hour: Int = 9) {
        let content = UNMutableNotificationContent()
        content.title = "Ready to crush it today? 🚀"
        content.body = "Your hype buddy is here when you need a boost!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_motivation",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                notificationLogger.error("Failed to schedule daily motivation: \(error)")
            } else {
                notificationLogger.info("Daily motivation scheduled for \(hour):00")
            }
        }
    }
    
    /// Cancel daily motivation reminder
    func cancelDailyMotivation() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_motivation"]
        )
    }
    
    // MARK: - Clear All
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
