//
//  ContextualMessageService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import Foundation
import OSLog

@MainActor
class ContextualMessageService: ObservableObject {
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "ContextualMessageService")
    let strapiRepository: StrapiRepository
    
    @Published var currentMessage: DesiMessage?
    @Published var isLoading = false
    
    init(strapiRepository: StrapiRepository) {
        self.strapiRepository = strapiRepository
    }
    
    // MARK: - Message Context Types
    enum MessageContext {
        case achievementUnlocked(Achievement)
        case levelUp(Int)
        case streakMilestone(Int)
        case dailyMotivation
        case progressMotivation(PerformanceData)
        case festivalContext(String)
        case workoutCompletion
        case wellnessReminder
        case workoutMotivation
        case nutritionTip
        case sleepAdvice
        case hydrationReminder
        case stressRelief
        case meditationGuidance
    }
    
    struct PerformanceData {
        let steps: Int
        let calories: Double
        let hydration: Double
        let sleepHours: Double
        let improvement: Double // Percentage improvement
    }
    
    // MARK: - Main Message Selection
    func selectContextualMessage(
        context: MessageContext,
        userLevel: Int,
        achievements: [Achievement], // Not fully used yet, but for future
        streakDays: Int,
        languagePreference: String = "hinglish"
    ) async -> DesiMessage? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allMessages = try await strapiRepository.getDesiMessages()
            let activeMessages = allMessages.data.filter { $0.isActive }
            
            let filteredMessages = filterMessagesByContext(
                messages: activeMessages,
                context: context,
                userLevel: userLevel,
                streakDays: streakDays,
                languagePreference: languagePreference
            )
            
            let selectedMessage = selectBestMessage(messages: filteredMessages, context: context)
            
            if let message = selectedMessage {
                currentMessage = message
                await updateMessageUsage(message) // Usage tracking will be implemented in future updates
                logger.debug("Selected message: \(message.messageText)")
            }
            
            return selectedMessage
        } catch {
            logger.error("Failed to select contextual message: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Message Filtering
    private func filterMessagesByContext(
        messages: [DesiMessage],
        context: MessageContext,
        userLevel: Int,
        streakDays: Int,
        languagePreference: String
    ) -> [DesiMessage] {
        return messages.filter { message in
            // Filter by message type
            guard message.messageType == getMessageType(for: context) else { return false }
            
            // Filter by user level
            guard userLevel >= message.minLevel && userLevel <= message.maxLevel else { return false }
            
            // Filter by language preference
            guard message.languageStyle == languagePreference || message.languageStyle == "any" else { return false }
            
            // Context-specific filtering
            switch context {
            case .achievementUnlocked(let achievement):
                return message.achievementCategory == achievement.category.rawValue || message.achievementCategory == nil
                
            case .streakMilestone(let days):
                return message.streakDays == days || message.streakDays == nil
                
            case .festivalContext(let festival):
                return message.festivalContext == festival || message.festivalContext == "any"
                
            default:
                return true
            }
        }
    }
    
    // MARK: - Message Type Mapping
    private func getMessageType(for context: MessageContext) -> String {
        switch context {
        case .achievementUnlocked: return "achievement_celebration"
        case .levelUp: return "level_up"
        case .streakMilestone: return "streak_milestone"
        case .dailyMotivation: return "daily_motivation"
        case .progressMotivation: return "progress_motivation"
        case .festivalContext: return "festival_context"
        case .workoutCompletion: return "workout_completion"
        case .wellnessReminder: return "wellness_reminder"
        case .workoutMotivation: return "workout_completion" // Reuse workout completion type
        case .nutritionTip: return "wellness_reminder" // Reuse wellness reminder type
        case .sleepAdvice: return "wellness_reminder" // Reuse wellness reminder type
        case .hydrationReminder: return "wellness_reminder" // Reuse wellness reminder type
        case .stressRelief: return "wellness_reminder" // Reuse wellness reminder type
        case .meditationGuidance: return "wellness_reminder" // Reuse wellness reminder type
        }
    }
    
    // MARK: - Best Message Selection
    private func selectBestMessage(messages: [DesiMessage], context: MessageContext) -> DesiMessage? {
        guard !messages.isEmpty else { return nil }
        
        // Sort by priority (highest first)
        let sortedMessages = messages.sorted { $0.priority > $1.priority }
        
        // Get messages with highest priority
        let highestPriority = sortedMessages.first?.priority ?? 0
        let highPriorityMessages = sortedMessages.filter { $0.priority == highestPriority }
        
        // If multiple high priority messages, select least used
        if highPriorityMessages.count > 1 {
            return highPriorityMessages.min { $0.usageCount < $1.usageCount }
        }
        
        return highPriorityMessages.first
    }
    
    // MARK: - Usage Tracking
    private func updateMessageUsage(_ message: DesiMessage) async {
        // Usage tracking will be implemented in future updates
        // This would update the usage_count and last_used fields
        logger.debug("Message usage updated for: \(message.messageText)")
    }
    
    // MARK: - Convenience Methods for Different Contexts
    
    // Home/Daily Context
    func getAchievementMessage(for achievement: Achievement, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .achievementUnlocked(achievement),
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    func getLevelUpMessage(for newLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .levelUp(newLevel),
            userLevel: newLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    func getStreakMessage(for days: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .streakMilestone(days),
            userLevel: 1, // Default level, can be adjusted
            achievements: [],
            streakDays: days
        )
    }
    
    func getDailyMotivation(userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .dailyMotivation,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    func getFestivalMessage(for festival: String) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .festivalContext(festival),
            userLevel: 1, // Default level, can be adjusted
            achievements: [],
            streakDays: 0
        )
    }
    
    // Workout Context
    func getWorkoutMotivation(workoutType: String, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .workoutMotivation,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    func getWorkoutCompletionMessage(workoutType: String, duration: Int, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .workoutCompletion,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    // Nutrition Context
    func getNutritionTip(mealType: String, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .nutritionTip,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    // Sleep Context
    func getSleepAdvice(sleepHours: Double, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .sleepAdvice,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    // Hydration Context
    func getHydrationReminder(currentHydration: Double, targetHydration: Double, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .hydrationReminder,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    // Wellness Context
    func getStressReliefAdvice(stressLevel: Int, userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .stressRelief,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
    
    func getMeditationGuidance(userLevel: Int) async -> DesiMessage? {
        return await selectContextualMessage(
            context: .meditationGuidance,
            userLevel: userLevel,
            achievements: [],
            streakDays: 0
        )
    }
}

// MARK: - Festival Detection
extension ContextualMessageService {
    func getCurrentFestival() -> String? {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        // Simple festival detection (can be enhanced)
        switch (month, day) {
        case (10, 24...31), (11, 1...5): // Diwali period
            return "diwali"
        case (3, 8...15): // Holi period
            return "holi"
        case (8, 15...22): // Rakhi period
            return "rakhi"
        case (8, 15): // Independence Day
            return "independence_day"
        case (1, 26): // Republic Day
            return "republic_day"
        default:
            return nil
        }
    }
}
