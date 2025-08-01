//
//  ProfileViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//


import Combine
import SwiftUI
import Foundation
import OSLog

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profileData: ProfileData
    @Published var uiMessage: String? = nil
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    private let healthService: HealthService
    private let logger = Logger(subsystem: "com.TrailBlazeWellness.Fitglide-ios", category: "ProfileViewModel")
    private var healthVitals: [HealthVitalsEntry] = [] // Cache for health vitals
    @ObservedObject var achievementService: AchievementService
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository, healthService: HealthService) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.healthService = healthService
        self.achievementService = AchievementService(strapiRepository: strapiRepository, authRepository: authRepository)
        self.profileData = ProfileData(
            firstName: nil,
            lastName: nil,
            email: nil,
            weight: nil,
            height: nil,
            gender: nil,
            dob: nil,
            activityLevel: nil,
            weightLossGoal: nil,
            weightLossStrategy: nil,
            stepGoal: nil,
            waterGoal: nil,
            calorieGoal: nil,
            bmi: nil,
            bmr: nil,
            tdee: nil,
            steps: nil,
            caloriesBurned: nil,
            notificationsEnabled: true,
            maxGreetingsEnabled: true,
            createdAt: nil,
            themePreference: nil
        )
        logger.debug("Auth State - UserID: \(authRepository.authState.userId ?? "nil"), JWT: \(authRepository.authState.jwt?.prefix(10) ?? "nil")")
        
        // Fetch data
        Task {
            await fetchProfileData()
            await fetchHealthData()
            await achievementService.loadAchievements()
        }
    }
    
    // Computed properties for weight loss progress
    var initialWeight: Double? {
        healthVitals
            .sorted(by: { ($0.createdAt ?? "") < ($1.createdAt ?? "") })
            .first?
            .WeightInKilograms
            .map { Double($0) }
    }
    
    var currentWeight: Double? {
        healthVitals
            .sorted(by: { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") })
            .first?
            .WeightInKilograms
            .map { Double($0) } ?? profileData.weight
    }
    
    var weightLost: Double? {
        guard let initial = initialWeight, let current = currentWeight else { return nil }
        return initial - current
    }
    
    var weightLossProgress: Float {
        guard let lost = weightLost, let goal = profileData.weightLossGoal, goal > 0 else { return 0 }
        return min(Float(lost / goal), 1.0)
    }
    
    var motivationalMessage: String {
        switch weightLossProgress {
        case 0:
            return "Keep the focus going!"
        case 0.45...0.55:
            return "You've reached halfway!"
        case 0.95...1.0:
            return "Congratulations, you achieved it!"
        default:
            return "Keep going, you're making progress!"
        }
    }
    
    func fetchProfileData() async {
        do {
            guard let userId = authRepository.authState.userId else {
                let errorMessage = "Missing user ID for fetching profile data"
                logger.error("\(errorMessage)")
                uiMessage = errorMessage
                return
            }
            guard let jwt = authRepository.authState.jwt else {
                let errorMessage = "Missing JWT for fetching profile data"
                logger.error("\(errorMessage)")
                uiMessage = errorMessage
                return
            }
            logger.debug("Fetching profile for user ID: \(userId) with JWT: \(jwt.prefix(10))...")
            
            // Try fetching with retry
            for attempt in 1...3 {
                do {
                    // Fetch user profile
                    let userProfile = try await strapiRepository.getUserProfile()
                    logger.debug("Fetched user profile (attempt \(attempt)) - ID: \(userProfile.id), FirstName: \(userProfile.firstName ?? "nil"), LastName: \(userProfile.lastName ?? "nil"), Email: \(userProfile.email)")
                    
                    // Fetch and cache health vitals
                    let healthVitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
                    self.healthVitals = healthVitalsResponse.data // Cache the health vitals
                    logger.debug("Fetched \(healthVitalsResponse.data.count) health vitals records for user \(userId)")
                    let latestVitals = healthVitalsResponse.data.sorted(by: { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }).first
                    
                    // Update profile data
                    self.profileData.firstName = userProfile.firstName
                    self.profileData.lastName = userProfile.lastName
                    self.profileData.email = userProfile.email
                    self.profileData.notificationsEnabled = userProfile.notificationsEnabled ?? true
                    self.profileData.maxGreetingsEnabled = userProfile.maxGreetingsEnabled ?? true
                    self.profileData.createdAt = userProfile.createdAt
                    
                    if let vitals = latestVitals {
                        updateProfileData(with: vitals)
                        logger.debug("Updated profileData with health vitals - Weight: \(vitals.WeightInKilograms?.description ?? "nil") kg, Height: \(vitals.height?.description ?? "nil") cm")
                    } else {
                        logger.debug("No health vitals found for user \(userId)")
                    }
                    
                    calculateMetrics()
                    logger.debug("Completed profile data fetch for user \(userId)")
                    uiMessage = nil
                    objectWillChange.send()
                    return
                } catch {
                    logger.error("Attempt \(attempt) failed: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            logger.error("Data corrupted: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .keyNotFound(let key, let context):
                            logger.error("Key not found: \(key.stringValue), context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .typeMismatch(let type, let context):
                            logger.error("Type mismatch: expected \(type), context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .valueNotFound(let type, let context):
                            logger.error("Value not found: expected \(type), context: \(context.debugDescription), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        @unknown default:
                            logger.error("Unknown decoding error: \(decodingError)")
                        }
                    }
                    if attempt == 3 {
                        let errorMessage = "Failed to fetch profile after 3 attempts: \(error.localizedDescription)"
                        logger.error("\(errorMessage)")
                        uiMessage = errorMessage
                    }
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1-second delay
                }
            }
        } catch {
            let errorMessage = "Unexpected error in fetchProfileData: \(error.localizedDescription)"
            logger.error("\(errorMessage)")
            uiMessage = errorMessage
        }
    }
    
    func fetchHealthData() async {
        do {
            try await healthService.requestAuthorization()
            let today = Date()
            let steps = try await healthService.getSteps(date: today)
            let calories = try await healthService.getCaloriesBurned(date: today)
            
            self.profileData.steps = Float(steps)
            self.profileData.caloriesBurned = calories
            logger.debug("Fetched HealthKit data: steps=\(steps), calories=\(calories)")
            objectWillChange.send()
        } catch {
            let errorMessage = "Failed to fetch HealthKit data: \(error.localizedDescription)"
            uiMessage = errorMessage
            logger.error("\(errorMessage)")
        }
    }
    
    func savePersonalData() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    let errorMessage = "Missing user ID for saving personal data"
                    logger.error("\(errorMessage)")
                    uiMessage = errorMessage
                    return
                }
                guard authRepository.authState.jwt != nil else {
                    let errorMessage = "Missing JWT for saving personal data"
                    logger.error("\(errorMessage)")
                    uiMessage = errorMessage
                    return
                }
                let profileRequest = UserProfileRequest(
                    username: nil,
                    firstName: profileData.firstName,
                    lastName: profileData.lastName,
                    email: profileData.email,
                    mobile: nil,
                    notificationsEnabled: profileData.notificationsEnabled,
                    maxGreetingsEnabled: profileData.maxGreetingsEnabled,
                    athleteId: nil,
                    stravaConnected: nil,
                    themePreference: nil,
                )
                logger.debug("Saving personal data for user \(userId): FirstName: \(profileRequest.firstName ?? "nil"), LastName: \(profileRequest.lastName ?? "nil")")
                let updatedProfile = try await strapiRepository.updateUserProfile(userId: userId, data: profileRequest)
                self.profileData.firstName = updatedProfile.firstName
                self.profileData.lastName = updatedProfile.lastName
                self.profileData.email = updatedProfile.email
                self.profileData.notificationsEnabled = updatedProfile.notificationsEnabled ?? true
                self.profileData.maxGreetingsEnabled = updatedProfile.maxGreetingsEnabled ?? true
                self.profileData.createdAt = updatedProfile.createdAt
                logger.debug("Saved personal data for user \(userId)")
                uiMessage = "Personal data saved successfully"
                objectWillChange.send()
            } catch {
                let errorMessage = "Failed to save personal data: \(error.localizedDescription)"
                uiMessage = errorMessage
                logger.error("\(errorMessage)")
            }
        }
    }
    
    private func saveHealthVitals() async {
        do {
            guard let userId = authRepository.authState.userId else {
                uiMessage = "User ID not found"
                return
            }
            
            let vitalsRequest = HealthVitalsRequest(
                WeightInKilograms: profileData.weight.map { Int($0) },
                height: profileData.height.map { Int($0) },
                gender: profileData.gender,
                date_of_birth: profileData.dob,
                activity_level: profileData.activityLevel,
                weight_loss_goal: profileData.weightLossGoal.map { Int($0) },
                stepGoal: profileData.stepGoal,
                waterGoal: profileData.waterGoal,
                calorieGoal: profileData.calorieGoal,
                weight_loss_strategy: profileData.weightLossStrategy,
                users_permissions_user: UserId(id: userId),
                BMI: profileData.bmi,
                BMR: profileData.bmr
            )
            
            logger.debug("Saving health vitals for user \(userId): Weight: \(vitalsRequest.WeightInKilograms?.description ?? "nil") kg")
            
            // Fetch existing health vitals
            let healthVitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            self.healthVitals = healthVitalsResponse.data // Update cache
            
            // Update or insert
            if let latestVitals = healthVitalsResponse.data.sorted(by: { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }).first {
                logger.debug("Updating existing health vitals, document ID: \(latestVitals.documentId)")
                _ = try await strapiRepository.updateHealthVitals(documentId: latestVitals.documentId, data: vitalsRequest)
            } else {
                logger.debug("No existing health vitals, posting new record")
                _ = try await strapiRepository.postHealthVitals(data: vitalsRequest)
            }
            
            // Refresh cache
            self.healthVitals = try await strapiRepository.getHealthVitals(userId: userId).data
            
            uiMessage = "Health data saved successfully"
            logger.debug("Saved health vitals for user \(userId)")
            objectWillChange.send()
        } catch {
            let errorMessage = "Failed to save health data: \(error.localizedDescription)"
            uiMessage = errorMessage
            logger.error("\(errorMessage)")
        }
    }
    
    private func calculateMetrics() {
        guard let weight = profileData.weight,
              let height = profileData.height,
              let gender = profileData.gender,
              let dob = profileData.dob,
              let activityLevel = profileData.activityLevel else {
            logger.debug("Insufficient data to calculate metrics")
            return
        }
        
        // BMI
        let heightMeters = height / 100.0
        let bmi = weight / (heightMeters * heightMeters)
        self.profileData.bmi = bmi
        
        // BMR (Mifflin-St Jeor)
        let isoFormatter = ISO8601DateFormatter()
        let age = Calendar.current.dateComponents([.year], from: isoFormatter.date(from: dob) ?? Date(), to: Date()).year ?? 30
        let bmr: Double
        if gender.lowercased() == "male" {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
        self.profileData.bmr = bmr
        
        // TDEE
        let activityMultipliers: [String: Double] = [
            "Sedentary (little/no exercise)": 1.2,
            "Light exercise (1-3 days/week)": 1.375,
            "Moderate exercise (3-5 days/week)": 1.55,
            "Heavy exercise (6-7 days/week)": 1.725,
            "Very heavy exercise (Twice/day)": 1.9
        ]
        let tdee = bmr * (activityMultipliers[activityLevel] ?? 1.2)
        self.profileData.tdee = tdee
        
        // New goal calculations
        computeGoalsFromTDEE()
        
        logger.debug("Calculated metrics: BMI=\(bmi), BMR=\(bmr), TDEE=\(tdee)")
        objectWillChange.send()
    }
    
    struct ProfileData {
        var firstName: String?
        var lastName: String?
        var email: String?
        var weight: Double?
        var height: Double?
        var gender: String?
        var dob: String?
        var activityLevel: String?
        var weightLossGoal: Double?
        var weightLossStrategy: String?
        var stepGoal: Int?
        var waterGoal: Float?
        var calorieGoal: Int?
        var bmi: Double?
        var bmr: Double?
        var tdee: Double?
        var steps: Float?
        var caloriesBurned: Float?
        var notificationsEnabled: Bool
        var maxGreetingsEnabled: Bool
        var createdAt: String?
        var themePreference: String?
    }
    
    func saveGoals() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    let errorMessage = "Missing user ID for saving goals"
                    logger.error("\(errorMessage)")
                    uiMessage = errorMessage
                    return
                }
                guard authRepository.authState.jwt != nil else {
                    let errorMessage = "Missing JWT for saving goals"
                    logger.error("\(errorMessage)")
                    uiMessage = errorMessage
                    return
                }

                // Recalculate before building request
                calculateMetrics()

                let vitalsRequest = HealthVitalsRequest(
                    WeightInKilograms: profileData.weight.map { Int($0) },
                    height: profileData.height.map { Int($0) },
                    gender: profileData.gender,
                    date_of_birth: profileData.dob,
                    activity_level: profileData.activityLevel,
                    weight_loss_goal: profileData.weightLossGoal.map { Int($0) },
                    stepGoal: profileData.stepGoal,
                    waterGoal: profileData.waterGoal,
                    calorieGoal: profileData.calorieGoal,
                    weight_loss_strategy: profileData.weightLossStrategy,
                    users_permissions_user: UserId(id: userId),
                    BMI: profileData.bmi,
                    BMR: profileData.bmr
                )
                
                logger.debug("Saving goals for user \(userId): Steps: \(self.profileData.stepGoal ?? -1), Water: \(self.profileData.waterGoal ?? -1), Calories: \(self.profileData.calorieGoal ?? -1)")

                // Fetch existing health vitals
                let healthVitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
                self.healthVitals = healthVitalsResponse.data // Update cache
                logger.debug("Fetched \(healthVitalsResponse.data.count) health vitals records for user \(userId)")

                // Update or insert
                if let latestVitals = healthVitalsResponse.data.sorted(by: { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }).first {
                    logger.debug("Updating existing goals, document ID: \(latestVitals.documentId)")
                    let updatedVitals = try await strapiRepository.updateHealthVitals(documentId: latestVitals.documentId, data: vitalsRequest)
                    updateProfileData(with: updatedVitals.data)
                    self.healthVitals = try await strapiRepository.getHealthVitals(userId: userId).data // Refresh cache
                } else {
                    logger.debug("No existing goals, posting new record")
                    let newVitals = try await strapiRepository.postHealthVitals(data: vitalsRequest)
                    updateProfileData(with: newVitals.data)
                    self.healthVitals = try await strapiRepository.getHealthVitals(userId: userId).data // Refresh cache
                }

                // Estimate duration to goal
                let weeks = profileData.weightLossGoal.map { goal in
                    switch profileData.weightLossStrategy {
                    case "Lean-(0.25 kg/week)": return Int(goal / 0.25)
                    case "Aggressive-(0.5 kg/week)": return Int(goal / 0.5)
                    case "Custom": return Int(goal / 0.25)
                    default: return 0
                    }
                } ?? 0

                uiMessage = "\(weeks) weeks to lose \(profileData.weightLossGoal.map { Int($0) } ?? 0) kg with \(profileData.weightLossStrategy ?? "")"
                logger.debug("Saved goals for user \(userId)")
                objectWillChange.send()
            } catch {
                let errorMessage = "Failed to save goals: \(error.localizedDescription)"
                uiMessage = errorMessage
                logger.error("\(errorMessage)")
            }
        }
    }

    private func updateProfileData(with vitals: HealthVitalsEntry) {
        profileData.weight = vitals.WeightInKilograms.map { Double($0) }
        profileData.height = vitals.height.map { Double($0) }
        profileData.gender = vitals.gender
        profileData.dob = vitals.date_of_birth
        profileData.activityLevel = vitals.activity_level
        profileData.weightLossGoal = vitals.weight_loss_goal.map { Double($0) }
        profileData.stepGoal = vitals.stepGoal
        profileData.waterGoal = vitals.waterGoal
        profileData.calorieGoal = vitals.calorieGoal
        profileData.weightLossStrategy = vitals.weight_loss_strategy
    }
    
    private func computeGoalsFromTDEE() {
        guard let tdee = profileData.tdee,
              let weight = profileData.weight,
              let strategy = profileData.weightLossStrategy,
              let weightLossGoal = profileData.weightLossGoal else {
            logger.debug("Insufficient data to compute goals from TDEE")
            return
        }
        
        var dailyDeficit: Double = 0
        var weeks: Int = 0
        
        switch strategy {
        case "Lean-(0.25 kg/week)":
            dailyDeficit = 250
            weeks = Int(weightLossGoal / 0.25)
        case "Aggressive-(0.5 kg/week)":
            dailyDeficit = 500
            weeks = Int(weightLossGoal / 0.5)
        case "Custom":
            dailyDeficit = 300
            weeks = Int(weightLossGoal / 0.3)
        default:
            logger.warning("Unrecognized strategy: \(strategy)")
            dailyDeficit = 250
        }
        
        // Calculate calorie goal
        let calorieGoal = max(1000, tdee - dailyDeficit)
        profileData.calorieGoal = Int(calorieGoal)
        
        // Estimate steps from deficit — assume 0.04 kcal/step
        let estimatedSteps = dailyDeficit / 0.04
        profileData.stepGoal = Int(estimatedSteps)
        
        // Estimate hydration: 0.033L per kg
        profileData.waterGoal = Float(weight * 0.033)
        
        logger.debug("Computed goals → Calories: \(calorieGoal), Steps: \(estimatedSteps), Water: \(self.profileData.waterGoal ?? 0) L, Weeks: \(weeks)")
    }
    
    // MARK: - Settings Management
    
    // MARK: - Computed Properties for Dynamic Data
    var memberSinceYear: String {
        // Get from user profile creation date
        if let createdAt = profileData.createdAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = formatter.date(from: createdAt) {
                let yearFormatter = DateFormatter()
                yearFormatter.dateFormat = "yyyy"
                return yearFormatter.string(from: date)
            }
        }
        return "2024" // Default fallback
    }
    
    var wellnessScore: String {
        // Calculate wellness score based on various health metrics
        var score = 0.0
        var factors = 0
        
        // Weight management (25%)
        if let weightLost = weightLost, let goal = profileData.weightLossGoal, goal > 0 {
            let weightProgress = min(weightLost / goal, 1.0)
            score += weightProgress * 25
            factors += 1
        }
        
        // Activity level (25%)
        if let steps = profileData.steps, let stepGoal = profileData.stepGoal, stepGoal > 0 {
            let stepProgress = min(Double(steps) / Double(stepGoal), 1.0)
            score += stepProgress * 25
            factors += 1
        }
        
        // Hydration (20%) - Get from health vitals
        if let waterGoal = profileData.waterGoal, waterGoal > 0 {
            // Use a default hydration progress for now
            let waterProgress = 0.8 // 80% hydration
            score += waterProgress * 20
            factors += 1
        }
        
        // Sleep quality (15%) - Use default
        let sleepProgress = 0.85 // 85% sleep quality
        score += sleepProgress * 15
        factors += 1
        
        // Heart rate (15%) - Use default
        let heartRateProgress = 0.9 // 90% heart rate health
        score += heartRateProgress * 15
        factors += 1
        
        // If no factors available, return default
        if factors == 0 {
            return "85%"
        }
        
        return "\(Int(score))%"
    }
    
    var achievementsCount: String {
        return "\(achievementService.achievements.count)"
    }
    
    // MARK: - Update Methods
    func updateWeight(_ weight: Double) {
        profileData.weight = weight
        Task {
            await saveHealthVitals()
        }
    }
    
    func updateHeight(_ height: Double) {
        profileData.height = height
        Task {
            await saveHealthVitals()
        }
    }
    
    func updateActivityLevel(_ activityLevel: String) {
        profileData.activityLevel = activityLevel
        Task {
            await saveHealthVitals()
        }
    }
    
    func updateWeightLossStrategy(_ strategy: String) {
        profileData.weightLossStrategy = strategy
        Task {
            await saveHealthVitals()
        }
    }
    
    func updateUserSettings(
        themePreference: String,
        notificationsEnabled: Bool,
        maxGreetingsEnabled: Bool
    ) async {
        guard let userId = authRepository.authState.userId else {
            uiMessage = "User ID not found"
            return
        }
        
        do {
            let settingsData: [String: Any] = [
                "themePreference": themePreference,
                "notificationsEnabled": notificationsEnabled,
                "maxGreetingsEnabled": maxGreetingsEnabled
            ]
            
            let _ = try await strapiRepository.updateUser(userId: userId, data: settingsData)
            
            // Update local profile data
            profileData.themePreference = themePreference
            profileData.notificationsEnabled = notificationsEnabled
            profileData.maxGreetingsEnabled = maxGreetingsEnabled
            
            uiMessage = "Settings updated successfully"
            logger.debug("Updated settings for user \(userId)")
            objectWillChange.send()
        } catch {
            let errorMessage = "Failed to update settings: \(error.localizedDescription)"
            uiMessage = errorMessage
            logger.error("\(errorMessage)")
        }
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async {
        guard let userId = authRepository.authState.userId else {
            uiMessage = "User ID not found"
            return
        }
        
        // TODO: Implement actual account deletion with Strapi
        // For now, just show a confirmation message
        uiMessage = "Account deletion feature is being implemented. Please contact support@fitglide.in for immediate account deletion."
        logger.info("Account deletion requested for user \(userId)")
    }
}
