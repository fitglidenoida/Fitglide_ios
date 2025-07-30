//
//  SmartNotificationService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import Foundation
import UserNotifications
import HealthKit
import SwiftUI

@MainActor
class SmartNotificationService: ObservableObject {
    @Published var scheduledNotifications: [SmartNotification] = []
    @Published var isEnabled = true
    
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        
        setupNotificationCenter()
    }
    
    // MARK: - Setup
    private func setupNotificationCenter() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("SmartNotificationService: Notification permission granted")
            } else if let error = error {
                print("SmartNotificationService: Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Smart Notifications
    
    func scheduleContextualNotifications() async {
        guard isEnabled else { return }
        
        // Clear existing notifications
        await clearAllNotifications()
        
        // Schedule new contextual notifications
        await scheduleActivityReminders()
        await scheduleHydrationReminders()
        await scheduleSleepReminders()
        await scheduleNutritionReminders()
        await scheduleHealthAlerts()
        await scheduleGoalReminders()
        await schedulePeriodReminders()
        
        print("SmartNotificationService: Scheduled \(scheduledNotifications.count) contextual notifications")
    }
    
    // MARK: - Activity Reminders
    
    private func scheduleActivityReminders() async {
        do {
            let steps = try await healthService.getSteps(date: Date())
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            // Morning activity reminder
            if currentHour < 10 && steps < 1000 {
                await scheduleNotification(
                    title: "Start Your Day Active",
                    body: "You've only taken \(Int(steps)) steps. Time for a morning walk!",
                    category: .activity,
                    trigger: createTimeTrigger(hour: 10, minute: 0)
                )
            }
            
            // Afternoon activity reminder
            if currentHour >= 12 && currentHour < 16 && steps < 3000 {
                await scheduleNotification(
                    title: "Midday Movement",
                    body: "You're at \(Int(steps)) steps. Take a lunch break walk!",
                    category: .activity,
                    trigger: createTimeTrigger(hour: 14, minute: 0)
                )
            }
            
            // Evening activity reminder
            if currentHour >= 18 && steps < 6000 {
                await scheduleNotification(
                    title: "Evening Energy",
                    body: "You're at \(Int(steps)) steps. Evening walk to reach your goal?",
                    category: .activity,
                    trigger: createTimeTrigger(hour: 19, minute: 0)
                )
            }
            
            // Sitting reminder
            await scheduleSittingReminder()
            
        } catch {
            print("SmartNotificationService: Failed to schedule activity reminders: \(error)")
        }
    }
    
    private func scheduleSittingReminder() async {
        // Check if user has been inactive for too long
        let lastActivity = UserDefaults.standard.object(forKey: "lastActivityTime") as? Date ?? Date()
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivity)
        
        if timeSinceLastActivity > 2 * 3600 { // 2 hours
            await scheduleNotification(
                title: "Time to Move",
                body: "You've been sitting for 2 hours. Stand up and stretch!",
                category: .activity,
                trigger: createTimeTrigger(hour: Calendar.current.component(.hour, from: Date()), minute: Calendar.current.component(.minute, from: Date()) + 5)
            )
        }
    }
    
    // MARK: - Hydration Reminders
    
    private func scheduleHydrationReminders() async {
        do {
            let waterIntake = try await healthService.getWaterIntake(date: Date())
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            // Morning hydration
            if currentHour < 10 && waterIntake < 500 {
                await scheduleNotification(
                    title: "Hydration Check",
                    body: "Start your day with a glass of water!",
                    category: .hydration,
                    trigger: createTimeTrigger(hour: 9, minute: 0)
                )
            }
            
            // Midday hydration
            if currentHour >= 12 && currentHour < 16 && waterIntake < 1000 {
                await scheduleNotification(
                    title: "Stay Hydrated",
                    body: "You've had \(Int(waterIntake))ml of water. Time for a refill!",
                    category: .hydration,
                    trigger: createTimeTrigger(hour: 15, minute: 0)
                )
            }
            
            // Evening hydration
            if currentHour >= 18 && waterIntake < 1500 {
                await scheduleNotification(
                    title: "Hydration Goal",
                    body: "You're at \(Int(waterIntake))ml. Almost there!",
                    category: .hydration,
                    trigger: createTimeTrigger(hour: 20, minute: 0)
                )
            }
            
        } catch {
            print("SmartNotificationService: Failed to schedule hydration reminders: \(error)")
        }
    }
    
    // MARK: - Sleep Reminders
    
    private func scheduleSleepReminders() async {
        do {
            let sleepData = try await healthService.getSleep(date: Date())
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            // Sleep preparation reminder
            if currentHour >= 21 && currentHour < 23 {
                await scheduleNotification(
                    title: "Prepare for Sleep",
                    body: "Start winding down for better sleep quality",
                    category: .sleep,
                    trigger: createTimeTrigger(hour: 22, minute: 0)
                )
            }
            
            // Sleep debt reminder
            if sleepData.total < 6 * 3600 { // Less than 6 hours
                await scheduleNotification(
                    title: "Sleep Debt Alert",
                    body: "You're building up sleep debt. Aim for 7-9 hours tonight",
                    category: .sleep,
                    trigger: createTimeTrigger(hour: 21, minute: 30)
                )
            }
            
        } catch {
            print("SmartNotificationService: Failed to schedule sleep reminders: \(error)")
        }
    }
    
    // MARK: - Nutrition Reminders
    
    private func scheduleNutritionReminders() async {
        do {
            let nutrition = try await healthService.getNutritionData(date: Date())
            let currentHour = Calendar.current.component(.hour, from: Date())
            
            // Breakfast reminder
            if currentHour < 10 && nutrition.caloriesConsumed < 200 {
                await scheduleNotification(
                    title: "Breakfast Time",
                    body: "Fuel your day with a healthy breakfast!",
                    category: .nutrition,
                    trigger: createTimeTrigger(hour: 8, minute: 30)
                )
            }
            
            // Lunch reminder
            if currentHour >= 12 && currentHour < 14 && nutrition.caloriesConsumed < 600 {
                await scheduleNotification(
                    title: "Lunch Break",
                    body: "Time for a nutritious lunch to maintain energy",
                    category: .nutrition,
                    trigger: createTimeTrigger(hour: 13, minute: 0)
                )
            }
            
            // Dinner reminder
            if currentHour >= 18 && currentHour < 20 && nutrition.caloriesConsumed < 1200 {
                await scheduleNotification(
                    title: "Dinner Time",
                    body: "Complete your daily nutrition with a balanced dinner",
                    category: .nutrition,
                    trigger: createTimeTrigger(hour: 19, minute: 0)
                )
            }
            
        } catch {
            print("SmartNotificationService: Failed to schedule nutrition reminders: \(error)")
        }
    }
    
    // MARK: - Health Alerts
    
    private func scheduleHealthAlerts() async {
        do {
            let heartRate = try await healthService.getHeartRate(date: Date())
            let hrv = try await healthService.getHRV(date: Date())
            
            // High heart rate alert
            if heartRate.average > 100 {
                await scheduleNotification(
                    title: "Heart Rate Alert",
                    body: "Your heart rate is elevated. Consider taking a break",
                    category: .health,
                    trigger: createTimeTrigger(hour: Calendar.current.component(.hour, from: Date()), minute: Calendar.current.component(.minute, from: Date()) + 2)
                )
            }
            
            // Low HRV alert
            if let hrvData = hrv, let sdnn = hrvData.sdnn, sdnn < 30 {
                await scheduleNotification(
                    title: "Recovery Alert",
                    body: "Your HRV indicates high stress. Consider rest or light activity",
                    category: .health,
                    trigger: createTimeTrigger(hour: Calendar.current.component(.hour, from: Date()), minute: Calendar.current.component(.minute, from: Date()) + 2)
                )
            }
            
        } catch {
            print("SmartNotificationService: Failed to schedule health alerts: \(error)")
        }
    }
    
    // MARK: - Goal Reminders
    
    private func scheduleGoalReminders() async {
        do {
            let steps = try await healthService.getSteps(date: Date())
            let stepGoal = UserDefaults.standard.float(forKey: "stepGoal") > 0 ? UserDefaults.standard.float(forKey: "stepGoal") : 10000
            
            let progress = (Float(steps) / stepGoal) * 100
            
            // 75% goal reminder
            if progress >= 75 && progress < 90 {
                await scheduleNotification(
                    title: "Goal Progress",
                    body: "You're \(Int(progress))% to your step goal! Keep going!",
                    category: .motivation,
                    trigger: createTimeTrigger(hour: Calendar.current.component(.hour, from: Date()), minute: Calendar.current.component(.minute, from: Date()) + 5)
                )
            }
            
            // 90% goal reminder
            if progress >= 90 && progress < 100 {
                await scheduleNotification(
                    title: "Almost There!",
                    body: "You're \(Int(progress))% to your step goal. Final push!",
                    category: .motivation,
                    trigger: createTimeTrigger(hour: Calendar.current.component(.hour, from: Date()), minute: Calendar.current.component(.minute, from: Date()) + 5)
                )
            }
            
        } catch {
            print("SmartNotificationService: Failed to schedule goal reminders: \(error)")
        }
    }
    
    // MARK: - Period Reminders
    
    private func schedulePeriodReminders() async {
        // This would integrate with the PeriodsViewModel
        // For now, we'll create a basic reminder structure
        
        await scheduleNotification(
            title: "Cycle Tracking",
            body: "Don't forget to log your symptoms today",
            category: .period,
            trigger: createTimeTrigger(hour: 20, minute: 0)
        )
    }
    
    // MARK: - Helper Methods
    
    private func scheduleNotification(title: String, body: String, category: NotificationCategory, trigger: UNNotificationTrigger) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            
            let notification = SmartNotification(
                id: request.identifier,
                title: title,
                body: body,
                category: category,
                scheduledTime: Date()
            )
            
            scheduledNotifications.append(notification)
            
        } catch {
            print("SmartNotificationService: Failed to schedule notification: \(error)")
        }
    }
    
    private func createTimeTrigger(hour: Int, minute: Int) -> UNNotificationTrigger {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }
    
    private func clearAllNotifications() async {
        await notificationCenter.removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    // MARK: - Public Methods
    
    func updateActivityTime() {
        UserDefaults.standard.set(Date(), forKey: "lastActivityTime")
    }
    
    func toggleNotifications() {
        isEnabled.toggle()
        if isEnabled {
            Task {
                await scheduleContextualNotifications()
            }
        } else {
            Task {
                await clearAllNotifications()
            }
        }
    }
    
    func refreshNotifications() {
        Task {
            await scheduleContextualNotifications()
        }
    }
}

// MARK: - Data Models

struct SmartNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let category: NotificationCategory
    let scheduledTime: Date
}

enum NotificationCategory: String, CaseIterable {
    case activity = "activity"
    case hydration = "hydration"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case health = "health"
    case motivation = "motivation"
    case period = "period"
    
    var icon: String {
        switch self {
        case .activity: return "figure.walk"
        case .hydration: return "drop.fill"
        case .sleep: return "bed.double.fill"
        case .nutrition: return "fork.knife"
        case .health: return "heart.fill"
        case .motivation: return "star.fill"
        case .period: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .activity: return .green
        case .hydration: return .blue
        case .sleep: return .purple
        case .nutrition: return .orange
        case .health: return .red
        case .motivation: return .yellow
        case .period: return .pink
        }
    }
} 