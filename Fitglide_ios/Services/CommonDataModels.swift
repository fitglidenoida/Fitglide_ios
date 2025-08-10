//
//  CommonDataModels.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 22/07/25.
//

import Foundation
import SwiftUI

// MARK: - Color Extensions
extension Color {
    var gradientColors: [Color] {
        switch self {
        case .blue: return [.blue, .cyan]
        case .green: return [.green, .mint]
        case .purple: return [.purple, .pink]
        case .orange: return [.orange, .yellow]
        case .red: return [.red, .pink]
        case .teal: return [.teal, .cyan]
        case .indigo: return [.indigo, .purple]
        default: return [self, self.opacity(0.7)]
        }
    }
}

// MARK: - Workout Types
enum WorkoutType: String, CaseIterable, Codable {
    case walking = "walking"
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case strength = "strength"
    case yoga = "yoga"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .strength: return "Strength"
        case .yoga: return "Yoga"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .other: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Base Data Protocol
protocol BaseDataProtocol: Equatable, Codable {
    var id: String { get }
}

// MARK: - Common Health Data
struct HealthMetrics: Equatable, Codable {
    let steps: Int
    let caloriesBurned: Double
    let heartRate: Int?
    let sleepHours: Double
    let hydration: Double
    let weight: Double?
    let date: Date
    
    static let empty = HealthMetrics(
        steps: 0,
        caloriesBurned: 0,
        heartRate: nil,
        sleepHours: 0,
        hydration: 0,
        weight: nil,
        date: Date()
    )
}

// MARK: - Common User Data
struct UserProfile: Equatable, Codable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String?
    let weight: Double?
    let height: Double?
    let gender: String?
    let dateOfBirth: String?
    let activityLevel: String?
    let stepGoal: Int?
    let waterGoal: Double?
    let calorieGoal: Int?
    let notificationsEnabled: Bool
    let maxGreetingsEnabled: Bool
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    static let empty = UserProfile(
        id: "",
        firstName: nil,
        lastName: nil,
        email: nil,
        weight: nil,
        height: nil,
        gender: nil,
        dateOfBirth: nil,
        activityLevel: nil,
        stepGoal: nil,
        waterGoal: nil,
        calorieGoal: nil,
        notificationsEnabled: true,
        maxGreetingsEnabled: true
    )
}

// MARK: - Common Goal Data
struct GoalData: Equatable, Codable {
    let type: GoalType
    let target: Double
    let current: Double
    let unit: String
    let deadline: Date?
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    enum GoalType: String, CaseIterable, Codable {
        case steps = "steps"
        case calories = "calories"
        case weight = "weight"
        case hydration = "hydration"
        case sleep = "sleep"
        case workout = "workout"
        
        var displayName: String {
            switch self {
            case .steps: return "Steps"
            case .calories: return "Calories"
            case .weight: return "Weight"
            case .hydration: return "Hydration"
            case .sleep: return "Sleep"
            case .workout: return "Workout"
            }
        }
        
        var icon: String {
            switch self {
            case .steps: return "figure.walk"
            case .calories: return "flame.fill"
            case .weight: return "scalemass.fill"
            case .hydration: return "drop.fill"
            case .sleep: return "bed.double.fill"
            case .workout: return "dumbbell.fill"
            }
        }
    }
}

// MARK: - Common Achievement Data
struct Achievement: Equatable, Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let isUnlocked: Bool
    let unlockedDate: Date?
    let progress: Double?
    let target: Double?
    
    // New properties for enhanced system
    let level: Int
    let fitCoinsReward: Int
    let badgeImageName: String?
    let isHidden: Bool
    let unlockCondition: String?
    
    var badgeColor: Color {
        switch category {
        case .fitness: return .blue
        case .nutrition: return .green
        case .social: return .purple
        case .streak: return .orange
        case .milestone: return .red
        case .wellness: return .teal
        case .challenge: return .indigo
        }
    }
    
    enum AchievementCategory: String, CaseIterable, Codable {
        case fitness = "fitness"
        case nutrition = "nutrition"
        case social = "social"
        case streak = "streak"
        case milestone = "milestone"
        case wellness = "wellness"
        case challenge = "challenge"
        
        var displayName: String {
            switch self {
            case .fitness: return "Fitness"
            case .nutrition: return "Nutrition"
            case .social: return "Social"
            case .streak: return "Streak"
            case .milestone: return "Milestone"
            case .wellness: return "Wellness"
            case .challenge: return "Challenge"
            }
        }
    }
}

// MARK: - Level System
struct Level: Equatable, Codable, Identifiable {
    let id: Int
    let name: String
    let hindiName: String
    let description: String
    let requiredAchievements: Int
    let fitCoinsReward: Int
    let isUnlocked: Bool
    let unlockedDate: Date?
    let achievements: [Achievement]
    
    var progress: Double {
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        return min(Double(unlockedCount) / Double(requiredAchievements), 1.0)
    }
    
    var isCompleted: Bool {
        return achievements.filter { $0.isUnlocked }.count >= requiredAchievements
    }
}

// MARK: - FitCoins System
struct FitCoinsWallet: Equatable, Codable {
    let balance: Int
    let totalEarned: Int
    let totalSpent: Int
    let transactionHistory: [FitCoinsTransaction]
    
    var canAfford: (Int) -> Bool {
        return { [self] amount in
            self.balance >= amount
        }
    }
}

struct FitCoinsTransaction: Equatable, Codable, Identifiable {
    let id: String
    let amount: Int
    let type: TransactionType
    let description: String
    let date: Date
    let relatedAchievement: String?
    
    enum TransactionType: String, Codable {
        case earned = "earned"
        case spent = "spent"
        case bonus = "bonus"
        case penalty = "penalty"
    }
}

// MARK: - Common Challenge Data
struct Challenge: Equatable, Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let goal: Double
    let current: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let participants: [ChallengeParticipant]
    let status: ChallengeStatus
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    enum ChallengeType: String, CaseIterable, Codable {
        case solo = "solo"
        case pack = "pack"
        case packVsPack = "pack_vs_pack"
        case `public` = "public"
        
        var displayName: String {
            switch self {
            case .solo: return "Solo"
            case .pack: return "Pack"
            case .packVsPack: return "Pack vs Pack"
            case .public: return "Public"
            }
        }
    }
    
    enum ChallengeStatus: String, CaseIterable, Codable {
        case active = "active"
        case completed = "completed"
        case expired = "expired"
        case pending = "pending"
        
        var displayName: String {
            switch self {
            case .active: return "Active"
            case .completed: return "Completed"
            case .expired: return "Expired"
            case .pending: return "Pending"
            }
        }
    }
}

struct ChallengeParticipant: Equatable, Codable, Identifiable {
    let id: String
    let name: String
    let progress: Double
    let rank: Int?
    let avatarUrl: String?
}





// MARK: - Common Workout Data
struct WorkoutData: Equatable, Codable, Identifiable {
    let id: String
    let type: WorkoutType
    let duration: TimeInterval
    let caloriesBurned: Double
    let distance: Double?
    let steps: Int?
    let heartRate: Int?
    let date: Date
    let notes: String?
    

}

// MARK: - Common Sleep Data
struct SleepData: Equatable, Codable {
    let date: Date
    let totalSleep: TimeInterval
    let deepSleep: TimeInterval
    let remSleep: TimeInterval
    let lightSleep: TimeInterval
    let awakeTime: TimeInterval
    let bedtime: Date
    let wakeTime: Date
    let quality: SleepQuality
    
    enum SleepQuality: String, CaseIterable, Codable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        
        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            }
        }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
    }
}

// MARK: - Common Social Data
struct SocialData: Equatable, Codable {
    let friends: [Friend]
    let packs: [Pack]
    let posts: [Post]
    let cheers: [Cheer]
    
    struct Friend: Equatable, Codable, Identifiable {
        let id: String
        let name: String
        let avatarUrl: String?
        let isOnline: Bool
        let lastActivity: Date?
    }
    
    struct Pack: Equatable, Codable, Identifiable {
        let id: String
        let name: String
        let description: String
        let memberCount: Int
        let isPrivate: Bool
        let avatarUrl: String?
    }
    
    struct Post: Equatable, Codable, Identifiable {
        let id: String
        let authorId: String
        let authorName: String
        let content: String
        let imageUrl: String?
        let likes: Int
        let comments: Int
        let createdAt: Date
        let type: PostType
        
        enum PostType: String, Codable {
            case workout = "workout"
            case achievement = "achievement"
            case meal = "meal"
            case general = "general"
        }
    }
    
    struct Cheer: Equatable, Codable, Identifiable {
        let id: String
        let fromUserId: String
        let fromUserName: String
        let toUserId: String
        let message: String
        let createdAt: Date
    }
}

// MARK: - Common Analytics Data
struct AnalyticsData: Equatable, Codable {
    let period: AnalyticsPeriod
    let metrics: [AnalyticsMetric]
    let trends: [AnalyticsTrend]
    
    enum AnalyticsPeriod: String, CaseIterable, Codable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .day: return "Day"
            case .week: return "Week"
            case .month: return "Month"
            case .year: return "Year"
            }
        }
    }
    
    struct AnalyticsMetric: Equatable, Codable {
        let name: String
        let value: Double
        let unit: String
        let change: Double?
        let changeType: ChangeType?
        
        enum ChangeType: String, Codable {
            case increase = "increase"
            case decrease = "decrease"
            case neutral = "neutral"
        }
    }
    
    struct AnalyticsTrend: Equatable, Codable {
        let date: Date
        let value: Double
        let label: String
    }
}

// MARK: - Common Extensions
extension Array where Element: BaseDataProtocol {
    func sortedById() -> [Element] {
        return sorted { $0.id < $1.id }
    }
}

extension Array where Element: HasDate {
    func sortedByDate(ascending: Bool = false) -> [Element] {
        return sorted { ascending ? $0.date < $1.date : $0.date > $1.date }
    }
}

protocol HasDate {
    var date: Date { get }
}

// MARK: - Common Computed Properties
extension HealthMetrics {
    var isComplete: Bool {
        return steps > 0 && caloriesBurned > 0 && sleepHours > 0
    }
    
    var healthScore: Int {
        var score = 0
        if steps >= 10000 { score += 25 }
        if caloriesBurned >= 2000 { score += 25 }
        if sleepHours >= 7 { score += 25 }
        if hydration >= 2.5 { score += 25 }
        return score
    }
}

extension UserProfile {
    var bmi: Double? {
        guard let weight = weight, let height = height, height > 0 else { return nil }
        let heightMeters = height / 100.0
        return weight / (heightMeters * heightMeters)
    }
    
    var bmiCategory: String? {
        guard let bmi = bmi else { return nil }
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
} 