//
//  ChallengeManager.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 11/08/25.
//

import Foundation
import Combine

class ChallengeManager: ObservableObject {
    @Published var currentChallenges: [Challenge] = []
    @Published var completedChallenges: [Challenge] = []
    @Published var challengeProgress: [String: Double] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let challengeService = ChallengeService()
    
    init() {
        setupDailyRefresh()
        Task {
            await loadChallengesFromStrapi()
        }
    }
    
    // MARK: - Challenge Types
    enum ChallengeType: String, CaseIterable, Codable {
        case dailySteps = "daily_steps"
        case weeklyWorkouts = "weekly_workouts"
        case monthlyDistance = "monthly_distance"
        case dailyCalories = "daily_calories"
        case weeklyActiveMinutes = "weekly_active_minutes"
        
        var title: String {
            switch self {
            case .dailySteps: return "Daily Steps"
            case .weeklyWorkouts: return "Weekly Workouts"
            case .monthlyDistance: return "Monthly Distance"
            case .dailyCalories: return "Daily Calories"
            case .weeklyActiveMinutes: return "Weekly Active Minutes"
            }
        }
        
        var icon: String {
            switch self {
            case .dailySteps: return "figure.walk"
            case .weeklyWorkouts: return "figure.run"
            case .monthlyDistance: return "location.fill"
            case .dailyCalories: return "flame.fill"
            case .weeklyActiveMinutes: return "clock.fill"
            }
        }
        
        var defaultTarget: Double {
            switch self {
            case .dailySteps: return 10000
            case .weeklyWorkouts: return 5
            case .monthlyDistance: return 50
            case .dailyCalories: return 500
            case .weeklyActiveMinutes: return 150
            }
        }
        
        var unit: String {
            switch self {
            case .dailySteps: return "steps"
            case .weeklyWorkouts: return "workouts"
            case .monthlyDistance: return "km"
            case .dailyCalories: return "cal"
            case .weeklyActiveMinutes: return "min"
            }
        }
    }
    
    // MARK: - Challenge Model
    struct Challenge: Identifiable, Codable {
        let id: String
        let type: ChallengeType
        let title: String
        let target: Double
        let currentValue: Double
        let startDate: Date
        let endDate: Date
        let isCompleted: Bool
        let completedDate: Date?
        
        var progress: Double {
            min(currentValue / target, 1.0)
        }
        
        var progressPercentage: Int {
            Int(progress * 100)
        }
        
        var isActive: Bool {
            let now = Date()
            return now >= startDate && now <= endDate && !isCompleted
        }
        
        var timeRemaining: String {
            let now = Date()
            let remaining = endDate.timeIntervalSince(now)
            
            if remaining <= 0 {
                return "Expired"
            }
            
            let days = Int(remaining / 86400)
            let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
            
            if days > 0 {
                return "\(days)d \(hours)h"
            } else {
                return "\(hours)h"
            }
        }
    }
    
    // MARK: - Public Methods
    func updateChallengeProgress(type: ChallengeType, value: Double) {
        if let index = currentChallenges.firstIndex(where: { $0.type == type && $0.isActive }) {
            let challenge = currentChallenges[index]
            let isCompleted = value >= challenge.target
            
            currentChallenges[index] = Challenge(
                id: challenge.id,
                type: type,
                title: challenge.title,
                target: challenge.target,
                currentValue: value,
                startDate: challenge.startDate,
                endDate: challenge.endDate,
                isCompleted: isCompleted,
                completedDate: isCompleted ? Date() : nil
            )
            
            challengeProgress[type.rawValue] = value
            
            // Sync with Strapi
            Task {
                await syncProgressToStrapi(challengeId: challenge.id, value: value, isCompleted: isCompleted)
            }
            
            // Check if challenge is completed
            if isCompleted && !challenge.isCompleted {
                completeChallenge(currentChallenges[index])
            }
        }
    }
    
    @MainActor
    private func syncProgressToStrapi(challengeId: String, value: Double, isCompleted: Bool) async {
        do {
            // Try direct Strapi API first
            let userId = "current_user_id" // This should come from auth
            
            try await challengeService.updateChallengeProgress(
                userId: userId,
                challengeId: challengeId,
                currentValue: value,
                isCompleted: isCompleted
            )
            print("✅ Challenge progress synced to Strapi")
            
        } catch {
            print("❌ Direct Strapi failed: \(error)")
            // Watch app works independently - no iPhone dependency
        }
    }
    
    func getActiveChallenges() -> [Challenge] {
        return currentChallenges.filter { $0.isActive }
    }
    
    func getCompletedChallenges() -> [Challenge] {
        return completedChallenges
    }
    
    // MARK: - Strapi Integration
    @MainActor
    func loadChallengesFromStrapi() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try direct Strapi API first
            let strapiChallenges = try await challengeService.fetchActiveChallenges()
            
            // Convert Strapi challenges to local Challenge objects
            let challenges = strapiChallenges.compactMap { strapiChallenge -> Challenge? in
                // Map metric to challenge type
                let challengeType: ChallengeType
                switch strapiChallenge.metric {
                case "steps":
                    challengeType = .dailySteps
                case "calories":
                    challengeType = .dailyCalories
                case "duration":
                    challengeType = .weeklyActiveMinutes
                case "reps":
                    challengeType = .weeklyWorkouts
                default:
                    challengeType = .dailySteps
                }
                
                // Use current date for start/end if not provided
                let calendar = Calendar.current
                let today = Date()
                let startDate: Date
                if let startDateString = strapiChallenge.startDate,
                   let parsedStartDate = ISO8601DateFormatter().date(from: startDateString) {
                    startDate = parsedStartDate
                } else {
                    startDate = calendar.startOfDay(for: today)
                }
                
                let endDate: Date
                if let endDateString = strapiChallenge.endDate,
                   let parsedEndDate = ISO8601DateFormatter().date(from: endDateString) {
                    endDate = parsedEndDate
                } else {
                    endDate = calendar.date(byAdding: .day, value: 7, to: today)!
                }
                
                return Challenge(
                    id: String(strapiChallenge.id),
                    type: challengeType,
                    title: strapiChallenge.title ?? "Challenge \(strapiChallenge.id)",
                    target: Double(max(strapiChallenge.goal, 1)),
                    currentValue: 0, // Will be updated with user progress
                    startDate: startDate,
                    endDate: endDate,
                    isCompleted: false,
                    completedDate: nil
                )
            }
            
            currentChallenges = challenges
            
            // Load user progress for these challenges
            await loadUserProgress()
            
        } catch {
            print("❌ Direct Strapi failed: \(error)")
            // No data available - show empty state
            currentChallenges = []
        }
        
        isLoading = false
    }
    
    // No mock data - show empty state when no data available
    
    @MainActor
    private func loadUserProgress() async {
        // TODO: Get userId from authentication
        let userId = "current_user_id" // This should come from auth
        
        do {
            let userProgress = try await challengeService.fetchUserChallengeProgress(userId: userId)
            
            // Update challenge progress
            for progress in userProgress {
                if let index = currentChallenges.firstIndex(where: { $0.id == progress.attributes.challengeId }) {
                    currentChallenges[index] = Challenge(
                        id: currentChallenges[index].id,
                        type: currentChallenges[index].type,
                        title: currentChallenges[index].title,
                        target: currentChallenges[index].target,
                        currentValue: progress.attributes.currentValue,
                        startDate: currentChallenges[index].startDate,
                        endDate: currentChallenges[index].endDate,
                        isCompleted: progress.attributes.isCompleted,
                        completedDate: progress.attributes.completedAt != nil ? ISO8601DateFormatter().date(from: progress.attributes.completedAt!) : nil
                    )
                    
                    challengeProgress[progress.attributes.challengeId] = progress.attributes.currentValue
                }
            }
            
        } catch {
            print("❌ Error loading user progress: \(error)")
        }
    }
    
    // MARK: - Private Methods
    // Removed hardcoded challenge generation - now using Strapi data
    
    private func completeChallenge(_ challenge: Challenge) {
        // Move to completed challenges
        completedChallenges.append(challenge)
        
        // Remove from current challenges
        currentChallenges.removeAll { $0.id == challenge.id }
        
        // Trigger completion notification
        NotificationCenter.default.post(
            name: .challengeCompleted,
            object: nil,
            userInfo: ["challenge": challenge]
        )
        
        // Progress is already synced to Strapi in updateChallengeProgress
    }
    
    private func setupDailyRefresh() {
        // Set up timer to refresh challenges from Strapi daily
        Timer.publish(every: 3600, on: .main, in: .common) // Check every hour
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.loadChallengesFromStrapi()
                }
            }
            .store(in: &cancellables)
    }
    
    // Removed local persistence - now using Strapi for data storage
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let challengeCompleted = Notification.Name("challengeCompleted")
}
