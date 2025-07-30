//
//  AchievementsEngine.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import Foundation
import SwiftUI
import OSLog
import UserNotifications

// MARK: - Achievement Engine
@MainActor
class AchievementsEngine: ObservableObject {
    @Published var unlockedAchievements: [Achievement] = []
    @Published var recentUnlock: Achievement?
    @Published var showUnlockAnimation = false
    
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "AchievementsEngine")
    
    // MARK: - Achievement Definitions
    static let allAchievements: [Achievement] = [
        // Fitness Achievements
        Achievement(
            id: "first_steps",
            title: "First Steps",
            description: "Complete your first 1,000 steps",
            icon: "figure.walk",
            category: .fitness,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 1000
        ),
        Achievement(
            id: "step_master",
            title: "Step Master",
            description: "Reach 10,000 steps in a day",
            icon: "figure.run",
            category: .fitness,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 10000
        ),
        Achievement(
            id: "marathon_walker",
            title: "Marathon Walker",
            description: "Walk 42,195 steps in a day",
            icon: "figure.hiking",
            category: .fitness,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 42195
        ),
        
        // Streak Achievements
        Achievement(
            id: "week_warrior",
            title: "Week Warrior",
            description: "Maintain a 7-day step streak",
            icon: "flame.fill",
            category: .streak,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 7
        ),
        Achievement(
            id: "month_master",
            title: "Month Master",
            description: "Maintain a 30-day step streak",
            icon: "calendar",
            category: .streak,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 30
        ),
        
        // Nutrition Achievements
        Achievement(
            id: "meal_tracker",
            title: "Meal Tracker",
            description: "Log your first meal",
            icon: "fork.knife",
            category: .nutrition,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 1
        ),
        Achievement(
            id: "nutrition_expert",
            title: "Nutrition Expert",
            description: "Log 50 meals",
            icon: "leaf.fill",
            category: .nutrition,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 50
        ),
        
        // Weight Loss Achievements
        Achievement(
            id: "first_pound",
            title: "First Pound",
            description: "Lose your first pound",
            icon: "scalemass.fill",
            category: .milestone,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 1
        ),
        Achievement(
            id: "weight_warrior",
            title: "Weight Warrior",
            description: "Lose 10 pounds",
            icon: "scalemass",
            category: .milestone,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 10
        ),
        
        // Social Achievements
        Achievement(
            id: "social_butterfly",
            title: "Social Butterfly",
            description: "Add your first friend",
            icon: "person.2.fill",
            category: .social,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 1
        ),
        Achievement(
            id: "team_player",
            title: "Team Player",
            description: "Join your first pack",
            icon: "person.3.fill",
            category: .social,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 1
        ),
        
        // Sleep Achievements
        Achievement(
            id: "sleep_well",
            title: "Sleep Well",
            description: "Get 8 hours of sleep",
            icon: "bed.double.fill",
            category: .fitness,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 8
        ),
        
        // Hydration Achievements
        Achievement(
            id: "water_champion",
            title: "Water Champion",
            description: "Drink 2.5L of water in a day",
            icon: "drop.fill",
            category: .fitness,
            isUnlocked: false,
            unlockedDate: nil,
            progress: nil,
            target: 2.5
        )
    ]
    
    init() {
        loadUnlockedAchievements()
    }
    
    // MARK: - Achievement Checking
    func checkStepAchievements(steps: Int) {
        checkAchievement(id: "first_steps", currentValue: Double(steps))
        checkAchievement(id: "step_master", currentValue: Double(steps))
        checkAchievement(id: "marathon_walker", currentValue: Double(steps))
    }
    
    func checkStreakAchievements(streakDays: Int) {
        checkAchievement(id: "week_warrior", currentValue: Double(streakDays))
        checkAchievement(id: "month_master", currentValue: Double(streakDays))
    }
    
    func checkNutritionAchievements(mealsLogged: Int) {
        checkAchievement(id: "meal_tracker", currentValue: Double(mealsLogged))
        checkAchievement(id: "nutrition_expert", currentValue: Double(mealsLogged))
    }
    
    func checkWeightLossAchievements(weightLost: Double) {
        checkAchievement(id: "first_pound", currentValue: weightLost)
        checkAchievement(id: "weight_warrior", currentValue: weightLost)
    }
    
    func checkSocialAchievements(friendsCount: Int, packsCount: Int) {
        checkAchievement(id: "social_butterfly", currentValue: Double(friendsCount))
        checkAchievement(id: "team_player", currentValue: Double(packsCount))
    }
    
    func checkSleepAchievements(sleepHours: Double) {
        checkAchievement(id: "sleep_well", currentValue: sleepHours)
    }
    
    func checkHydrationAchievements(hydrationLiters: Double) {
        checkAchievement(id: "water_champion", currentValue: hydrationLiters)
    }
    
    // MARK: - Core Achievement Logic
    private func checkAchievement(id: String, currentValue: Double) {
        guard let achievement = Self.allAchievements.first(where: { $0.id == id }) else {
            logger.error("Achievement with id \(id) not found")
            return
        }
        
        // Skip if already unlocked
        if isAchievementUnlocked(id: id) {
            return
        }
        
        // Check if achievement should be unlocked
        if currentValue >= (achievement.target ?? 0) {
            unlockAchievement(achievement)
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        // Create a new achievement instance with unlocked status
        let updatedAchievement = Achievement(
            id: achievement.id,
            title: achievement.title,
            description: achievement.description,
            icon: achievement.icon,
            category: achievement.category,
            isUnlocked: true,
            unlockedDate: Date(),
            progress: achievement.progress,
            target: achievement.target
        )
        
        unlockedAchievements.append(updatedAchievement)
        recentUnlock = updatedAchievement
        showUnlockAnimation = true
        
        // Save to UserDefaults
        saveUnlockedAchievements()
        
        // Log achievement unlock
        logger.info("Achievement unlocked: \(achievement.title)")
        
        // Show notification
        showAchievementNotification(achievement)
        
        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showUnlockAnimation = false
            self.recentUnlock = nil
        }
    }
    
    // MARK: - Persistence
    private func saveUnlockedAchievements() {
        do {
            let data = try JSONEncoder().encode(unlockedAchievements)
            userDefaults.set(data, forKey: "unlockedAchievements")
        } catch {
            logger.error("Failed to save unlocked achievements: \(error.localizedDescription)")
        }
    }
    
    private func loadUnlockedAchievements() {
        guard let data = userDefaults.data(forKey: "unlockedAchievements") else {
            unlockedAchievements = []
            return
        }
        
        do {
            unlockedAchievements = try JSONDecoder().decode([Achievement].self, from: data)
        } catch {
            logger.error("Failed to load unlocked achievements: \(error.localizedDescription)")
            unlockedAchievements = []
        }
    }
    
    // MARK: - Utility Methods
    func isAchievementUnlocked(id: String) -> Bool {
        return unlockedAchievements.contains { $0.id == id }
    }
    
    func getAchievementProgress(id: String, currentValue: Double) -> Double {
        guard let achievement = Self.allAchievements.first(where: { $0.id == id }),
              let target = achievement.target,
              target > 0 else {
            return 0.0
        }
        
        return min(currentValue / target, 1.0)
    }
    
    func getAchievementsByCategory(_ category: Achievement.AchievementCategory) -> [Achievement] {
        return Self.allAchievements.filter { $0.category == category }
    }
    
    func getUnlockedAchievementsByCategory(_ category: Achievement.AchievementCategory) -> [Achievement] {
        return unlockedAchievements.filter { $0.category == category }
    }
    
    func getTotalAchievements() -> Int {
        return Self.allAchievements.count
    }
    
    func getUnlockedCount() -> Int {
        return unlockedAchievements.count
    }
    
    func getCompletionPercentage() -> Double {
        guard getTotalAchievements() > 0 else { return 0.0 }
        return Double(getUnlockedCount()) / Double(getTotalAchievements())
    }
    
    // MARK: - Notifications
    private func showAchievementNotification(_ achievement: Achievement) {
        // Create local notification
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(achievement.title): \(achievement.description)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show achievement notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Reset (for testing)
    func resetAchievements() {
        unlockedAchievements = []
        saveUnlockedAchievements()
        logger.info("All achievements reset")
    }
}

// MARK: - Achievement Unlock Animation View
struct AchievementUnlockView: View {
    let achievement: Achievement
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            
            // Achievement card
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                
                // Title
                Text("🏆 Achievement Unlocked!")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.primary)
                
                // Achievement details
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.primary)
                    
                    Text(achievement.description)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Category badge
                Text(achievement.category.displayName)
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .scaleEffect(isShowing ? 1.0 : 0.8)
            .opacity(isShowing ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
        }
    }
}
