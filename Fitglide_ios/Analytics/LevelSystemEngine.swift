//
//  LevelSystemEngine.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - Level System Engine
@MainActor
class LevelSystemEngine: ObservableObject {
    @Published var levels: [Level] = []
    @Published var currentLevel: Level?
    @Published var showLevelUpAnimation = false
    @Published var recentlyUnlockedLevel: Level?
    
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "LevelSystemEngine")
    private let fitCoinsEngine: FitCoinsEngine
    
    init(fitCoinsEngine: FitCoinsEngine) {
        self.fitCoinsEngine = fitCoinsEngine
        setupLevels()
        loadLevelProgress()
        updateCurrentLevel()
    }
    
    // MARK: - Level Setup
    private func setupLevels() {
        levels = [
            Level(
                id: 1,
                name: "Shuruaat",
                hindiName: "शुरुआत",
                description: "The beginning of your fitness journey",
                requiredAchievements: 3,
                fitCoinsReward: 100,
                isUnlocked: true,
                unlockedDate: nil,
                achievements: []
            ),
            Level(
                id: 2,
                name: "Josh",
                hindiName: "जोश",
                description: "Building enthusiasm and momentum",
                requiredAchievements: 6,
                fitCoinsReward: 250,
                isUnlocked: false,
                unlockedDate: nil,
                achievements: []
            ),
            Level(
                id: 3,
                name: "Jazba",
                hindiName: "जज़्बा",
                description: "Passion and dedication take over",
                requiredAchievements: 10,
                fitCoinsReward: 500,
                isUnlocked: false,
                unlockedDate: nil,
                achievements: []
            ),
            Level(
                id: 4,
                name: "Shakti",
                hindiName: "शक्ति",
                description: "Power and strength manifest",
                requiredAchievements: 15,
                fitCoinsReward: 1000,
                isUnlocked: false,
                unlockedDate: nil,
                achievements: []
            ),
            Level(
                id: 5,
                name: "Moksha",
                hindiName: "मोक्ष",
                description: "Enlightenment and mastery achieved",
                requiredAchievements: 20,
                fitCoinsReward: 2500,
                isUnlocked: false,
                unlockedDate: nil,
                achievements: []
            )
        ]
    }
    
    // MARK: - Level Management
    func updateLevelProgress(with achievements: [Achievement]) {
        for i in 0..<levels.count {
            let levelAchievements = achievements.filter { $0.level == levels[i].id }
            levels[i] = Level(
                id: levels[i].id,
                name: levels[i].name,
                hindiName: levels[i].hindiName,
                description: levels[i].description,
                requiredAchievements: levels[i].requiredAchievements,
                fitCoinsReward: levels[i].fitCoinsReward,
                isUnlocked: levels[i].isUnlocked,
                unlockedDate: levels[i].unlockedDate,
                achievements: levelAchievements
            )
        }
        
        checkLevelUnlocks()
        updateCurrentLevel()
        saveLevelProgress()
    }
    
    private func checkLevelUnlocks() {
        for i in 0..<levels.count {
            let level = levels[i]
            
            // Skip if already unlocked
            if level.isUnlocked {
                continue
            }
            
            // Check if level should be unlocked
            let unlockedCount = level.achievements.filter { $0.isUnlocked }.count
            if unlockedCount >= level.requiredAchievements {
                unlockLevel(at: i)
            }
        }
    }
    
    private func unlockLevel(at index: Int) {
        let level = levels[index]
        let updatedLevel = Level(
            id: level.id,
            name: level.name,
            hindiName: level.hindiName,
            description: level.description,
            requiredAchievements: level.requiredAchievements,
            fitCoinsReward: level.fitCoinsReward,
            isUnlocked: true,
            unlockedDate: Date(),
            achievements: level.achievements
        )
        
        levels[index] = updatedLevel
        recentlyUnlockedLevel = updatedLevel
        showLevelUpAnimation = true
        
        // Award FitCoins for level completion
        fitCoinsEngine.rewardLevelCompletion(updatedLevel)
        
        logger.info("Level \(level.id) (\(level.name)) unlocked!")
        
        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showLevelUpAnimation = false
            self.recentlyUnlockedLevel = nil
        }
    }
    
    private func updateCurrentLevel() {
        // Find the highest unlocked level
        currentLevel = levels
            .filter { $0.isUnlocked }
            .max { $0.id < $1.id }
    }
    
    // MARK: - Level Information
    func getLevelProgress(_ level: Level) -> Double {
        let unlockedCount = level.achievements.filter { $0.isUnlocked }.count
        return min(Double(unlockedCount) / Double(level.requiredAchievements), 1.0)
    }
    
    func getNextLevel() -> Level? {
        guard let current = currentLevel else {
            return levels.first
        }
        
        return levels.first { $0.id == current.id + 1 }
    }
    
    func getLevelById(_ id: Int) -> Level? {
        return levels.first { $0.id == id }
    }
    
    func getUnlockedLevels() -> [Level] {
        return levels.filter { $0.isUnlocked }
    }
    
    func getLockedLevels() -> [Level] {
        return levels.filter { !$0.isUnlocked }
    }
    
    func getTotalLevels() -> Int {
        return levels.count
    }
    
    func getCompletedLevels() -> Int {
        return levels.filter { $0.isUnlocked }.count
    }
    
    func getOverallProgress() -> Double {
        guard getTotalLevels() > 0 else { return 0.0 }
        return Double(getCompletedLevels()) / Double(getTotalLevels())
    }
    
    // MARK: - Persistence
    private func saveLevelProgress() {
        do {
            let data = try JSONEncoder().encode(levels)
            userDefaults.set(data, forKey: "levelProgress")
        } catch {
            logger.error("Failed to save level progress: \(error.localizedDescription)")
        }
    }
    
    private func loadLevelProgress() {
        guard let data = userDefaults.data(forKey: "levelProgress") else {
            return // Use default levels from setup
        }
        
        do {
            let savedLevels = try JSONDecoder().decode([Level].self, from: data)
            // Merge saved progress with default levels
            for i in 0..<min(levels.count, savedLevels.count) {
                levels[i] = Level(
                    id: levels[i].id,
                    name: levels[i].name,
                    hindiName: levels[i].hindiName,
                    description: levels[i].description,
                    requiredAchievements: levels[i].requiredAchievements,
                    fitCoinsReward: levels[i].fitCoinsReward,
                    isUnlocked: savedLevels[i].isUnlocked,
                    unlockedDate: savedLevels[i].unlockedDate,
                    achievements: levels[i].achievements
                )
            }
        } catch {
            logger.error("Failed to load level progress: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset (for testing)
    func resetLevels() {
        setupLevels()
        saveLevelProgress()
        updateCurrentLevel()
        logger.info("All levels reset")
    }
}

// MARK: - Level Up Animation View
struct LevelUpAnimationView: View {
    let level: Level
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            
            // Level up card
            VStack(spacing: 24) {
                // Level icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Text("\(level.id)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(isShowing ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isShowing)
                
                // Title
                Text("🎉 LEVEL UP! 🎉")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.primary)
                    .scaleEffect(isShowing ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isShowing)
                
                // Level details
                VStack(spacing: 8) {
                    Text(level.name)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.primary)
                    
                    Text(level.hindiName)
                        .font(.custom("Poppins-Medium", size: 18))
                        .foregroundColor(.secondary)
                    
                    Text(level.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(isShowing ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.6), value: isShowing)
                
                // Reward
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    Text("+\(level.fitCoinsReward) FitCoins")
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(20)
                .opacity(isShowing ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.8), value: isShowing)
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(isShowing ? 1.0 : 0.8)
            .opacity(isShowing ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
        }
    }
}
