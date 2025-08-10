//
//  AchievementManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import Foundation
import SwiftUI
import OSLog
import Combine

// MARK: - Global Achievement Manager
@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var fitCoinsEngine: FitCoinsEngine
    @Published var levelSystemEngine: LevelSystemEngine
    @Published var achievementsEngine: AchievementsEngine
    
    @Published var showAchievementNotification = false
    @Published var showLevelUpNotification = false
    @Published var showFitCoinsNotification = false
    
    @Published var currentAchievement: Achievement?
    @Published var currentLevel: Level?
    @Published var currentFitCoinsTransaction: FitCoinsTransaction?
    
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "AchievementManager")
    
    private init() {
        let fitCoins = FitCoinsEngine()
        let levelSystem = LevelSystemEngine(fitCoinsEngine: fitCoins)
        let achievements = AchievementsEngine(fitCoinsEngine: fitCoins, levelSystemEngine: levelSystem)
        
        self.fitCoinsEngine = fitCoins
        self.levelSystemEngine = levelSystem
        self.achievementsEngine = achievements
        
        // Setup notifications after all properties are initialized
        DispatchQueue.main.async {
            self.setupNotifications()
        }
    }
    
    // MARK: - Notification Setup
    private func setupNotifications() {
        // Listen for achievement unlocks
        achievementsEngine.$recentUnlock
            .compactMap { $0 }
            .sink { [weak self] achievement in
                self?.showAchievementUnlock(achievement)
            }
            .store(in: &cancellables)
        
        // Listen for level ups
        levelSystemEngine.$recentlyUnlockedLevel
            .compactMap { $0 }
            .sink { [weak self] level in
                self?.showLevelUp(level)
            }
            .store(in: &cancellables)
        
        // Listen for FitCoins transactions
        fitCoinsEngine.$lastTransaction
            .compactMap { $0 }
            .sink { [weak self] transaction in
                self?.showFitCoinsTransaction(transaction)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Achievement Checking Methods
    func checkStepAchievements(steps: Int) {
        achievementsEngine.checkStepAchievements(steps: steps)
    }
    
    func checkWorkoutAchievements(workoutCount: Int, workoutType: String) {
        // Check first workout achievement
        if workoutCount == 1 {
            checkAchievement(id: "first_workout", currentValue: 1.0)
        }
        
        // Check running achievement
        if workoutType.lowercased().contains("running") {
            checkAchievement(id: "first_run", currentValue: 1.0)
        }
        
        // Check cycling achievement
        if workoutType.lowercased().contains("cycling") {
            checkAchievement(id: "cycling_complete", currentValue: 1.0)
        }
        
        // Check total workout achievements
        checkAchievement(id: "century_club", currentValue: Double(workoutCount))
        checkAchievement(id: "fitness_guru", currentValue: Double(workoutCount))
    }
    
    func checkStreakAchievements(streakDays: Int) {
        achievementsEngine.checkStreakAchievements(streakDays: streakDays)
        
        // Check additional streak achievements
        checkAchievement(id: "three_day_streak", currentValue: Double(streakDays))
        checkAchievement(id: "hundred_day_streak", currentValue: Double(streakDays))
        checkAchievement(id: "year_warrior", currentValue: Double(streakDays))
    }
    
    func checkSocialAchievements(friendsCount: Int, packsCount: Int) {
        achievementsEngine.checkSocialAchievements(friendsCount: friendsCount, packsCount: packsCount)
        
        // Check additional social achievements
        checkAchievement(id: "pack_leader", currentValue: Double(packsCount))
        checkAchievement(id: "community_champion", currentValue: Double(friendsCount))
    }
    
    func checkNutritionAchievements(mealsLogged: Int) {
        achievementsEngine.checkNutritionAchievements(mealsLogged: mealsLogged)
        
        // Check additional nutrition achievements
        checkAchievement(id: "all_meals_logged", currentValue: Double(mealsLogged))
    }
    
    func checkWellnessAchievements(sleepHours: Double, hydrationLiters: Double, stressLevel: Double) {
        achievementsEngine.checkSleepAchievements(sleepHours: sleepHours)
        achievementsEngine.checkHydrationAchievements(hydrationLiters: hydrationLiters)
        
        // Check additional wellness achievements
        checkAchievement(id: "zen_beast", currentValue: stressLevel)
        checkAchievement(id: "zen_master", currentValue: stressLevel)
    }
    
    func checkDistanceAchievements(distanceKm: Double) {
        checkAchievement(id: "distance_diva", currentValue: distanceKm)
        checkAchievement(id: "ultra_marathon", currentValue: distanceKm)
    }
    
    func checkChallengeAchievements(challengeCount: Int, wonChallenges: Int) {
        if challengeCount == 1 {
            checkAchievement(id: "first_challenge", currentValue: 1.0)
        }
        
        if wonChallenges >= 1 {
            checkAchievement(id: "challenge_winner", currentValue: Double(wonChallenges))
        }
    }
    
    // MARK: - Helper Methods
    private func checkAchievement(id: String, currentValue: Double) {
        guard let achievement = AchievementDefinitions.allAchievements.first(where: { $0.id == id }) else {
            return
        }
        
        if !achievementsEngine.isAchievementUnlocked(id: id) && currentValue >= (achievement.target ?? 0) {
            achievementsEngine.checkAchievement(id: id, currentValue: currentValue)
        }
    }
    
    // MARK: - Notification Display Methods
    private func showAchievementUnlock(_ achievement: Achievement) {
        currentAchievement = achievement
        showAchievementNotification = true
        
        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showAchievementNotification = false
            self.currentAchievement = nil
        }
    }
    
    private func showLevelUp(_ level: Level) {
        currentLevel = level
        showLevelUpNotification = true
        
        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showLevelUpNotification = false
            self.currentLevel = nil
        }
    }
    
    private func showFitCoinsTransaction(_ transaction: FitCoinsTransaction) {
        currentFitCoinsTransaction = transaction
        showFitCoinsNotification = true
        
        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showFitCoinsNotification = false
            self.currentFitCoinsTransaction = nil
        }
    }
    
    // MARK: - Utility Methods
    func getCurrentLevel() -> Level? {
        return levelSystemEngine.currentLevel
    }
    
    func getFitCoinsBalance() -> Int {
        return fitCoinsEngine.wallet.balance
    }
    
    func getTotalAchievements() -> Int {
        return achievementsEngine.getTotalAchievements()
    }
    
    func getUnlockedAchievements() -> Int {
        return achievementsEngine.getUnlockedCount()
    }
    
    func getCompletionPercentage() -> Double {
        return achievementsEngine.getCompletionPercentage()
    }
    
    func getLevelProgress() -> Double {
        guard let currentLevel = levelSystemEngine.currentLevel else { return 0.0 }
        return levelSystemEngine.getLevelProgress(currentLevel)
    }
    
    // MARK: - Reset (for testing)
    func resetAll() {
        achievementsEngine.resetAchievements()
        levelSystemEngine.resetLevels()
        fitCoinsEngine.resetWallet()
        logger.info("All achievement data reset")
    }
}

// MARK: - Achievement Notification Overlay
struct AchievementNotificationOverlay: View {
    @ObservedObject var achievementManager: AchievementManager
    
    var body: some View {
        ZStack {
            // Achievement Unlock Notification
            if achievementManager.showAchievementNotification,
               let achievement = achievementManager.currentAchievement {
                AchievementUnlockView(achievement: achievement, isShowing: $achievementManager.showAchievementNotification)
            }
            
            // Level Up Notification
            if achievementManager.showLevelUpNotification,
               let level = achievementManager.currentLevel {
                LevelUpAnimationView(level: level, isShowing: $achievementManager.showLevelUpNotification)
            }
            
            // FitCoins Transaction Notification
            if achievementManager.showFitCoinsNotification,
               let transaction = achievementManager.currentFitCoinsTransaction {
                VStack {
                    Spacer()
                    FitCoinsTransactionAlert(transaction: transaction, isShowing: $achievementManager.showFitCoinsNotification)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
        }
    }
}
