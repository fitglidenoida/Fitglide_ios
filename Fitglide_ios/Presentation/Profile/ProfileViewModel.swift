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

// MARK: - Goal System Enums
enum LifeGoalCategory: String, CaseIterable {
    case energyVitality = "Energy & Vitality"
    case confidenceBody = "Confidence & Body"
    case healthLongevity = "Health & Longevity"
    case stressWellness = "Stress & Wellness"
    case socialLifestyle = "Social & Lifestyle"
    
    var description: String {
        switch self {
        case .energyVitality: return "Feel more energetic and active throughout the day"
        case .confidenceBody: return "Feel confident and comfortable in your body"
        case .healthLongevity: return "Improve your health and stay active as you age"
        case .stressWellness: return "Reduce stress and improve your mental wellness"
        case .socialLifestyle: return "Keep up with family and enjoy social activities"
        }
    }
    
    var icon: String {
        switch self {
        case .energyVitality: return "bolt.fill"
        case .confidenceBody: return "heart.fill"
        case .healthLongevity: return "leaf.fill"
        case .stressWellness: return "brain.head.profile"
        case .socialLifestyle: return "person.2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .energyVitality: return "orange"
        case .confidenceBody: return "pink"
        case .healthLongevity: return "green"
        case .stressWellness: return "purple"
        case .socialLifestyle: return "blue"
        }
    }
}

enum LifeGoalType: String, CaseIterable {
    // Energy & Vitality
    case feelEnergetic = "Feel energetic throughout the day"
    case wakeUpRefreshed = "Wake up feeling refreshed"
    case haveEnergyForKids = "Have energy to play with kids"
    case stayActiveAtWork = "Stay active at work without fatigue"
    
    // Confidence & Body
    case feelConfidentInClothes = "Feel confident in my clothes"
    case feelStrongCapable = "Feel strong and capable"
    case improvePosture = "Improve my posture and presence"
    case feelGoodAboutBody = "Feel good about my body"
    
    // Health & Longevity
    case reduceHealthRisks = "Reduce my risk of health problems"
    case keepUpWithFamily = "Keep up with my family"
    case stayHealthyAging = "Stay healthy as I age"
    case betterSleepQuality = "Have better sleep quality"
    
    // Stress & Wellness
    case manageStressBetter = "Manage stress better"
    case feelRelaxedCalm = "Feel more relaxed and calm"
    case improveMood = "Improve my mood"
    case workLifeBalance = "Have better work-life balance"
    
    // Social & Lifestyle
    case keepUpWithFriends = "Keep up with friends on hikes"
    case activeWithFamily = "Be active with my family"
    case travelWithoutTired = "Travel without getting tired"
    case enjoyOutdoorActivities = "Enjoy outdoor activities"
    
    var category: LifeGoalCategory {
        switch self {
        case .feelEnergetic, .wakeUpRefreshed, .haveEnergyForKids, .stayActiveAtWork:
            return .energyVitality
        case .feelConfidentInClothes, .feelStrongCapable, .improvePosture, .feelGoodAboutBody:
            return .confidenceBody
        case .reduceHealthRisks, .keepUpWithFamily, .stayHealthyAging, .betterSleepQuality:
            return .healthLongevity
        case .manageStressBetter, .feelRelaxedCalm, .improveMood, .workLifeBalance:
            return .stressWellness
        case .keepUpWithFriends, .activeWithFamily, .travelWithoutTired, .enjoyOutdoorActivities:
            return .socialLifestyle
        }
    }
}

enum GoalTimeline: Int, CaseIterable {
    case twoWeeks = 2
    case oneMonth = 4
    case threeMonths = 12
    case sixMonths = 24
    
    var description: String {
        switch self {
        case .twoWeeks: return "2 weeks (quick wins)"
        case .oneMonth: return "1 month (noticeable changes)"
        case .threeMonths: return "3 months (significant improvement)"
        case .sixMonths: return "6 months (lifestyle transformation)"
        }
    }
}

enum GoalCommitmentLevel: String, CaseIterable {
    case casual = "Casual"
    case moderate = "Moderate"
    case dedicated = "Dedicated"
    
    var description: String {
        switch self {
        case .casual: return "I want to make small changes gradually"
        case .moderate: return "I'm ready to commit to regular habits"
        case .dedicated: return "I'm fully committed to transforming my lifestyle"
        }
    }
}

struct GoalRecommendation {
    let activities: [String]
    let nutrition: [String]
    let timeline: Int
    let successProbability: Double
    let milestones: [String]
}

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
    @ObservedObject var smartGoalsService: SmartGoalsService
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository, healthService: HealthService) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.healthService = healthService
        self.achievementService = AchievementService(strapiRepository: strapiRepository, authRepository: authRepository)
        self.smartGoalsService = SmartGoalsService(healthService: healthService, strapiRepository: strapiRepository, authRepository: authRepository)
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
            mealGoal: nil,
            sleepGoal: nil,
            bmi: nil,
            bmr: nil,
            tdee: nil,
            steps: nil,
            caloriesBurned: nil,
            notificationsEnabled: true,
            maxGreetingsEnabled: true,
            createdAt: nil,
            themePreference: nil,
            lifeGoalCategory: nil,
            lifeGoalType: nil,
            goalTimeline: nil,
            goalCommitmentLevel: nil,
            goalStartDate: nil,
            goalTargetDate: nil,
            goalProgressPercentage: nil,
            goalCurrentMilestone: nil,
            goalPredictedTimeline: nil,
            goalRecommendedActivities: nil,
            goalRecommendedNutrition: nil,
            goalSuccessProbability: nil,
            secondaryGoals: nil,
            goalPriority: nil,
            goalMilestones: nil,
            goalAchievements: nil,
            goalInsights: nil,
            goalRecommendations: nil,
            goalEnergyScore: nil,
            goalConfidenceScore: nil,
            goalStressScore: nil,
            goalSocialScore: nil,
            goalHealthScore: nil
        )
        logger.debug("Auth State - UserID: \(authRepository.authState.userId ?? "nil"), JWT: \(authRepository.authState.jwt?.prefix(10) ?? "nil")")
        
        // Fetch data
        Task {
            logger.debug("Starting ProfileViewModel initialization...")
            await fetchProfileData()
            await fetchHealthData()
            await achievementService.loadAchievements()
            
            // Check HealthKit permissions and log status
            logger.debug("Checking HealthKit permissions...")
            await healthService.logPermissionStatus()
            
            // Initialize smart goals if needed
            logger.debug("Initializing smart goals...")
            await smartGoalsService.initializeSmartGoalsIfNeeded()
            logger.debug("ProfileViewModel initialization complete")
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
            .map { Double($0) } ?? self.profileData.weight
    }
    
    var weightLost: Double? {
        guard let initial = initialWeight, let current = currentWeight else { return nil }
        return initial - current
    }
    
    var weightLossProgress: Float {
        guard let lost = weightLost, let goal = self.profileData.weightLossGoal, goal > 0 else { return 0 }
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
            
            // Calculate metrics after updating profile data
            calculateMetrics()
            logger.debug("Calculated metrics after updating profile data - BMI: \(self.profileData.bmi ?? 0), BMR: \(self.profileData.bmr ?? 0), TDEE: \(self.profileData.tdee ?? 0)")
        } else {
            logger.debug("No health vitals found for user \(userId)")
        }
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
    
    private func jsonString(from array: [String]?) -> String? {
        guard let array = array else { return nil }
        guard let data = try? JSONEncoder().encode(array) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func array(from jsonString: String?) -> [String]? {
        guard let str = jsonString, let data = str.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
    
    func fetchHealthData() async {
        do {
            try await healthService.requestAuthorization()
            let today = Date()
            
            // Try to fetch HealthKit data, but don't treat "no data" as an error
            do {
                let steps = try await healthService.getSteps(date: today)
                self.profileData.steps = Float(steps)
                logger.debug("Fetched HealthKit steps: \(steps)")
            } catch {
                logger.debug("No HealthKit steps data available for today: \(error.localizedDescription)")
                self.profileData.steps = 0
            }
            
            do {
                let calories = try await healthService.getCaloriesBurned(date: today)
                self.profileData.caloriesBurned = calories
                logger.debug("Fetched HealthKit calories: \(calories)")
            } catch {
                logger.debug("No HealthKit calories data available for today: \(error.localizedDescription)")
                self.profileData.caloriesBurned = 0
            }
            
            objectWillChange.send()
        } catch {
            let errorMessage = "Failed to request HealthKit authorization: \(error.localizedDescription)"
            uiMessage = errorMessage
            logger.error("\(errorMessage)")
        }
    }
    
    func savePersonalData() async {
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
                firstName: self.profileData.firstName,
                lastName: self.profileData.lastName,
                email: self.profileData.email,
                mobile: nil,
                notificationsEnabled: self.profileData.notificationsEnabled,
                maxGreetingsEnabled: self.profileData.maxGreetingsEnabled,
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
    
    func saveHealthVitals() async {
        do {
            guard let userId = authRepository.authState.userId else {
                uiMessage = "User ID not found"
                return
            }
            
            let vitalsRequest = HealthVitalsRequest(
                WeightInKilograms: self.profileData.weight.map { Int($0) },
                height: self.profileData.height.map { Int($0) },
                gender: self.profileData.gender,
                date_of_birth: self.profileData.dob,
                activity_level: self.profileData.activityLevel,
                weight_loss_goal: self.profileData.weightLossGoal.map { Int($0) },
                stepGoal: self.profileData.stepGoal,
                waterGoal: self.profileData.waterGoal,
                calorieGoal: self.profileData.calorieGoal,
                mealGoal: self.profileData.mealGoal,
                sleepGoal: self.profileData.sleepGoal,
                weight_loss_strategy: self.profileData.weightLossStrategy,
                users_permissions_user: UserId(id: userId),
                BMI: self.profileData.bmi,
                BMR: self.profileData.bmr,
                life_goal_category: self.profileData.lifeGoalCategory,
                life_goal_type: self.profileData.lifeGoalType,
                goal_timeline: self.profileData.goalTimeline,
                goal_commitment_level: self.profileData.goalCommitmentLevel,
                goal_start_date: self.profileData.goalStartDate,
                goal_target_date: self.profileData.goalTargetDate,
                goal_progress_percentage: self.profileData.goalProgressPercentage,
                goal_current_milestone: self.profileData.goalCurrentMilestone,
                goal_predicted_timeline: self.profileData.goalPredictedTimeline,
                goal_recommended_activities: self.profileData.goalRecommendedActivities,
                goal_recommended_nutrition: self.profileData.goalRecommendedNutrition,
                goal_success_probability: self.profileData.goalSuccessProbability,
                secondary_goals: self.profileData.secondaryGoals,
                goal_priority: self.profileData.goalPriority,
                goal_milestones: self.profileData.goalMilestones,
                goal_achievements: self.profileData.goalAchievements,
                goal_insights: self.profileData.goalInsights,
                goal_recommendations: self.profileData.goalRecommendations,
                goal_energy_score: self.profileData.goalEnergyScore,
                goal_confidence_score: self.profileData.goalConfidenceScore,
                goal_stress_score: self.profileData.goalStressScore,
                goal_social_score: self.profileData.goalSocialScore,
                goal_health_score: self.profileData.goalHealthScore
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
            
            // Recalculate metrics after saving
            await MainActor.run {
                calculateMetrics()
            }
            
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
        logger.debug("calculateMetrics called - Weight: \(self.profileData.weight ?? 0), Height: \(self.profileData.height ?? 0), Gender: \(self.profileData.gender ?? "nil"), DOB: \(self.profileData.dob ?? "nil"), Activity: \(self.profileData.activityLevel ?? "nil")")
        
        // Calculate BMI if we have weight and height
        if let weight = self.profileData.weight, let height = self.profileData.height {
            let heightMeters = height / 100.0
            let bmi = weight / (heightMeters * heightMeters)
            self.profileData.bmi = bmi
            logger.debug("Calculated BMI: \(bmi)")
        }
        
        // Calculate BMR and TDEE only if we have all required fields
        guard let weight = self.profileData.weight,
              let height = self.profileData.height,
              let gender = self.profileData.gender,
              let dob = self.profileData.dob,
              let activityLevel = self.profileData.activityLevel else {
            logger.debug("Insufficient data to calculate BMR/TDEE - missing: \(self.missingFields())")
            return
        }
        
        // BMR (Mifflin-St Jeor)
        let age = calculateAgeFromDOB(dob)
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
        
        logger.debug("Calculated metrics: BMI=\(self.profileData.bmi ?? 0), BMR=\(bmr), TDEE=\(tdee)")
        objectWillChange.send()
    }
    
    private func missingFields() -> String {
        var missing: [String] = []
        if self.profileData.weight == nil { missing.append("weight") }
        if self.profileData.height == nil { missing.append("height") }
        if self.profileData.gender == nil { missing.append("gender") }
        if self.profileData.dob == nil { missing.append("date of birth") }
        if self.profileData.activityLevel == nil { missing.append("activity level") }
        return missing.joined(separator: ", ")
    }
    
    private func calculateAgeFromDOB(_ dobString: String) -> Int {
        // Try ISO8601DateFormatter first
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dobString) {
            let age = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 30
            logger.debug("Calculated age: \(age) from DOB using ISO8601: \(dobString)")
            return age
        }
        
        // Try DateFormatter with different formats
        let dateFormatStrings = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd"
        ]
        
        for formatString in dateFormatStrings {
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            if let date = formatter.date(from: dobString) {
                let age = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 30
                logger.debug("Calculated age: \(age) from DOB using format \(formatString): \(dobString)")
                return age
            }
        }
        
        logger.warning("Could not parse DOB: \(dobString), using default age 30")
        return 30
    }
    

    
    // MARK: - Goal Management Methods
    
    func setLifeGoal(category: LifeGoalCategory, type: LifeGoalType, timeline: GoalTimeline, commitment: GoalCommitmentLevel) async {
        logger.info("Setting life goal: \(type.rawValue) for category: \(category.rawValue)")
        
        // Update the profile data
        await MainActor.run {
            self.profileData.lifeGoalCategory = category.rawValue
            self.profileData.lifeGoalType = type.rawValue
            self.profileData.goalTimeline = timeline.rawValue
            self.profileData.goalCommitmentLevel = commitment.rawValue
            self.profileData.goalStartDate = DateFormatter.yyyyMMdd.string(from: Date())
            
            // Calculate target date based on timeline
            let targetDate: Date
            switch timeline {
            case .twoWeeks:
                targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date()
            case .oneMonth:
                targetDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            case .threeMonths:
                targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            case .sixMonths:
                targetDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
            }
            self.profileData.goalTargetDate = DateFormatter.yyyyMMdd.string(from: targetDate)
        }
        
        // Save to Strapi
        await saveHealthVitals()
        
        // Refresh smart goals data
        await smartGoalsService.refreshSmartGoalsData()
        
        logger.info("Life goal set successfully")
    }
    

    
    private func generateGoalRecommendation(for goalType: LifeGoalType, timeline: GoalTimeline, commitment: GoalCommitmentLevel) -> GoalRecommendation {
        var activities: [String] = []
        var nutrition: [String] = []
        var milestones: [String] = []
        var successProbability: Double = 0.8
        
        // Base activities based on goal type
        switch goalType.category {
        case .energyVitality:
            activities = [
                "30 minutes of daily walking",
                "Strength training 2-3 times per week",
                "Morning stretching routine",
                "Regular sleep schedule (7-8 hours)"
            ]
            nutrition = [
                "Balanced meals with protein",
                "Stay hydrated (2-3L water daily)",
                "Limit caffeine after 2 PM",
                "Include energy-boosting foods"
            ]
            
        case .confidenceBody:
            activities = [
                "Strength training 3-4 times per week",
                "Cardio 2-3 times per week",
                "Posture exercises daily",
                "Flexibility training"
            ]
            nutrition = [
                "High protein diet",
                "Balanced macronutrients",
                "Regular meal timing",
                "Adequate hydration"
            ]
            
        case .healthLongevity:
            activities = [
                "150 minutes moderate cardio weekly",
                "Strength training 2-3 times per week",
                "Balance and flexibility exercises",
                "Regular health check-ups"
            ]
            nutrition = [
                "Mediterranean diet principles",
                "Anti-inflammatory foods",
                "Omega-3 rich foods",
                "Antioxidant-rich vegetables"
            ]
            
        case .stressWellness:
            activities = [
                "Daily meditation (10-20 minutes)",
                "Yoga or tai chi 2-3 times per week",
                "Deep breathing exercises",
                "Regular nature walks"
            ]
            nutrition = [
                "Stress-reducing foods",
                "Limit caffeine and alcohol",
                "Magnesium-rich foods",
                "Regular meal timing"
            ]
            
        case .socialLifestyle:
            activities = [
                "Group fitness classes",
                "Outdoor activities with friends",
                "Family walks or bike rides",
                "Social sports or activities"
            ]
            nutrition = [
                "Social meal planning",
                "Healthy snacks for activities",
                "Hydration for outdoor activities",
                "Balanced nutrition for energy"
            ]
        }
        
        // Adjust based on commitment level
        switch commitment {
        case .casual:
            activities = activities.map { "Start with: \($0)" }
            successProbability = 0.6
        case .moderate:
            successProbability = 0.8
        case .dedicated:
            activities = activities.map { "Commit to: \($0)" }
            successProbability = 0.9
        }
        
        // Generate milestones based on timeline
        let weekCount = timeline.rawValue
        milestones = [
            "Week 2: Establish new habits",
            "Week \(weekCount / 2): Notice first improvements",
            "Week \(weekCount): Achieve your goal"
        ]
        
        return GoalRecommendation(
            activities: activities,
            nutrition: nutrition,
            timeline: weekCount,
            successProbability: successProbability,
            milestones: milestones
        )
    }
    
    private func updateGoalRecommendations(_ recommendation: GoalRecommendation) {
        self.profileData.goalRecommendedActivities = recommendation.activities
        self.profileData.goalRecommendedNutrition = recommendation.nutrition
        self.profileData.goalMilestones = recommendation.milestones
        self.profileData.goalPredictedTimeline = recommendation.timeline
        self.profileData.goalSuccessProbability = recommendation.successProbability
    }
    
    func getGoalProgress() -> Double {
        guard let startDate = self.profileData.goalStartDate,
              let targetDate = self.profileData.goalTargetDate else {
            return 0
        }
        
        let formatter = ISO8601DateFormatter()
        guard let start = formatter.date(from: startDate),
              let target = formatter.date(from: targetDate) else {
            return 0.0
        }
        
        let now = Date()
        let totalDuration = target.timeIntervalSince(start)
        let elapsed = now.timeIntervalSince(start)
        
        let progress = min(max(elapsed / totalDuration, 0.0), 1.0)
        return progress * 100.0
    }
    
    func getCurrentMilestone() -> String {
        let progress = getGoalProgress()
        
        if progress < 25 {
            return "Getting started - establish your new habits"
        } else if progress < 50 {
            return "Building momentum - you're making progress!"
        } else if progress < 75 {
            return "Halfway there - keep up the great work!"
        } else if progress < 100 {
            return "Almost there - final push to your goal!"
        } else {
            return "Goal achieved - congratulations!"
        }
    }
    
    func getGoalInsights() -> [String] {
        var insights: [String] = []
        
        // Add insights based on current progress
        let progress = getGoalProgress()
        if progress > 0 {
            insights.append("You're \(Int(progress))% of the way to your goal")
        }
        
        // Add insights based on goal type
        if let goalType = self.profileData.lifeGoalType {
            switch goalType {
            case LifeGoalType.feelEnergetic.rawValue:
                insights.append("Focus on consistent sleep and regular movement")
            case LifeGoalType.feelConfidentInClothes.rawValue:
                insights.append("Strength training will help you feel stronger")
            case LifeGoalType.manageStressBetter.rawValue:
                insights.append("Daily meditation can significantly reduce stress")
            default:
                insights.append("Consistency is key to achieving your goal")
            }
        }
        
        return insights
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
        var mealGoal: Int?
        var sleepGoal: Float?
        var bmi: Double?
        var bmr: Double?
        var tdee: Double?
        var steps: Float?
        var caloriesBurned: Float?
        var notificationsEnabled: Bool
        var maxGreetingsEnabled: Bool
        var createdAt: String?
        var themePreference: String?
        
        // NEW: Life-Based Goal Fields
        var lifeGoalCategory: String?
        var lifeGoalType: String?
        var goalTimeline: Int?
        var goalCommitmentLevel: String?
        var goalStartDate: String?
        var goalTargetDate: String?
        var goalProgressPercentage: Double?
        var goalCurrentMilestone: String?
        var goalPredictedTimeline: Int?
        var goalRecommendedActivities: [String]?
        var goalRecommendedNutrition: [String]?
        var goalSuccessProbability: Double?
        var secondaryGoals: [String]?
        var goalPriority: String?
        var goalMilestones: [String]?
        var goalAchievements: [String]?
        var goalInsights: [String]?
        var goalRecommendations: [String]?
        var goalEnergyScore: Double?
        var goalConfidenceScore: Double?
        var goalStressScore: Double?
        var goalSocialScore: Double?
        var goalHealthScore: Double?
    }
    
    func saveGoals() async {
        do {
            guard let userId = authRepository.authState.userId else {
                let errorMessage = "Missing userId for saving goals"
                logger.error("\(errorMessage)")
                await MainActor.run {
                    uiMessage = errorMessage
                }
                return
            }

            guard authRepository.authState.jwt != nil else {
                let errorMessage = "Missing JWT for saving goals"
                logger.error("\(errorMessage)")
                await MainActor.run {
                    uiMessage = errorMessage
                }
                return
            }

            // Recalculate before building request
            await MainActor.run {
                calculateMetrics()
            }

            // Create a targeted request with only goal-related fields
            let vitalsRequest = HealthVitalsRequest(
                WeightInKilograms: nil,
                height: nil,
                gender: nil,
                date_of_birth: nil,
                activity_level: nil,
                weight_loss_goal: nil,
                stepGoal: self.profileData.stepGoal,
                waterGoal: self.profileData.waterGoal,
                calorieGoal: self.profileData.calorieGoal,
                mealGoal: self.profileData.mealGoal,
                sleepGoal: self.profileData.sleepGoal,
                weight_loss_strategy: nil,
                users_permissions_user: UserId(id: userId),
                BMI: nil,
                BMR: nil,
                life_goal_category: self.profileData.lifeGoalCategory,
                life_goal_type: self.profileData.lifeGoalType,
                goal_timeline: self.profileData.goalTimeline,
                goal_commitment_level: self.profileData.goalCommitmentLevel,
                goal_start_date: self.profileData.goalStartDate,
                goal_target_date: self.profileData.goalTargetDate,
                goal_progress_percentage: self.profileData.goalProgressPercentage,
                goal_current_milestone: self.profileData.goalCurrentMilestone,
                goal_predicted_timeline: self.profileData.goalPredictedTimeline,
                goal_recommended_activities: self.profileData.goalRecommendedActivities,  // Use [String]? directly
                goal_recommended_nutrition: self.profileData.goalRecommendedNutrition,   // Use [String]? directly
                goal_success_probability: self.profileData.goalSuccessProbability,
                secondary_goals: self.profileData.secondaryGoals,                        // Use [String]? directly
                goal_priority: self.profileData.goalPriority,
                goal_milestones: self.profileData.goalMilestones,                       // Use [String]? directly
                goal_achievements: self.profileData.goalAchievements,                   // Use [String]? directly
                goal_insights: self.profileData.goalInsights,                           // Use [String]? directly
                goal_recommendations: self.profileData.goalRecommendations,             // Use [String]? directly
                goal_energy_score: self.profileData.goalEnergyScore,
                goal_confidence_score: self.profileData.goalConfidenceScore,
                goal_stress_score: self.profileData.goalStressScore,
                goal_social_score: self.profileData.goalSocialScore,
                goal_health_score: self.profileData.goalHealthScore
            )
            
            logger.debug("Saving goals for user \(userId)")

            // Fetch existing health vitals
            let healthVitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            self.healthVitals = healthVitalsResponse.data // Update cache
            logger.debug("Fetched \(healthVitalsResponse.data.count) health vitals records for user \(userId)")

            // Update or insert
            if let latestVitals = healthVitalsResponse.data.sorted(by: { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }).first {
                logger.debug("Updating existing goals, document ID: \(latestVitals.documentId)")
                let updatedVitals = try await strapiRepository.updateHealthVitals(documentId: latestVitals.documentId, data: vitalsRequest)
                await MainActor.run {
                    updateProfileData(with: updatedVitals.data)
                }
                self.healthVitals = try await strapiRepository.getHealthVitals(userId: userId).data // Refresh cache
            } else {
                logger.debug("No existing goals, posting new record")
                let newVitals = try await strapiRepository.postHealthVitals(data: vitalsRequest)
                await MainActor.run {
                    updateProfileData(with: newVitals.data)
                }
                self.healthVitals = try await strapiRepository.getHealthVitals(userId: userId).data // Refresh cache
            }

            await MainActor.run {
                uiMessage = "Life goal set successfully!"
                objectWillChange.send()
            }
            logger.debug("Saved goals for user \(userId)")
        } catch {
            let errorMessage = "Failed to save goals: \(error.localizedDescription)"
            logger.error("\(errorMessage)")
            await MainActor.run {
                uiMessage = errorMessage
            }
        }
    }
    
    private func updateProfileData(with vitals: HealthVitalsEntry) {
        self.profileData.weight = vitals.WeightInKilograms.map { Double($0) }
        self.profileData.height = vitals.height.map { Double($0) }
        self.profileData.gender = vitals.gender
        self.profileData.dob = vitals.date_of_birth
        self.profileData.activityLevel = vitals.activity_level
        self.profileData.weightLossGoal = vitals.weight_loss_goal.map { Double($0) }
        self.profileData.stepGoal = vitals.stepGoal
        self.profileData.waterGoal = vitals.waterGoal
        self.profileData.calorieGoal = vitals.calorieGoal
        self.profileData.mealGoal = vitals.mealGoal
        self.profileData.sleepGoal = vitals.sleepGoal
        self.profileData.weightLossStrategy = vitals.weight_loss_strategy
        
        // NEW: Life-Based Goal Fields
        self.profileData.lifeGoalCategory = vitals.life_goal_category
        self.profileData.lifeGoalType = vitals.life_goal_type
        self.profileData.goalTimeline = vitals.goal_timeline
        self.profileData.goalCommitmentLevel = vitals.goal_commitment_level
        self.profileData.goalStartDate = vitals.goal_start_date
        self.profileData.goalTargetDate = vitals.goal_target_date
        self.profileData.goalProgressPercentage = vitals.goal_progress_percentage
        self.profileData.goalCurrentMilestone = vitals.goal_current_milestone
        self.profileData.goalPredictedTimeline = vitals.goal_predicted_timeline
        
        // Assign arrays directly
        self.profileData.goalRecommendedActivities = vitals.goal_recommended_activities
        self.profileData.goalRecommendedNutrition = vitals.goal_recommended_nutrition
        self.profileData.goalSuccessProbability = vitals.goal_success_probability
        self.profileData.secondaryGoals = vitals.secondary_goals
        self.profileData.goalPriority = vitals.goal_priority
        self.profileData.goalMilestones = vitals.goal_milestones
        self.profileData.goalAchievements = vitals.goal_achievements
        self.profileData.goalInsights = vitals.goal_insights
        self.profileData.goalRecommendations = vitals.goal_recommendations
        
        self.profileData.goalEnergyScore = vitals.goal_energy_score
        self.profileData.goalConfidenceScore = vitals.goal_confidence_score
        self.profileData.goalStressScore = vitals.goal_stress_score
        self.profileData.goalSocialScore = vitals.goal_social_score
        self.profileData.goalHealthScore = vitals.goal_health_score
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
    func updateWeight(_ weight: Double) async {
        profileData.weight = weight
        await saveHealthVitals()
    }
    
    func updateHeight(_ height: Double) async {
        profileData.height = height
        await saveHealthVitals()
    }
    
    func updateActivityLevel(_ activityLevel: String) async {
        profileData.activityLevel = activityLevel
        await saveHealthVitals()
    }
    
    func updateWeightLossStrategy(_ strategy: String) async {
        profileData.weightLossStrategy = strategy
        await saveHealthVitals()
    }
    
    func updateLifeGoal(_ goalType: String) async {
        // Update the local profile data
        profileData.lifeGoalType = goalType
        
        // Determine the category based on the goal type
        if let goalTypeEnum = LifeGoalType.allCases.first(where: { $0.rawValue == goalType }) {
            profileData.lifeGoalCategory = goalTypeEnum.category.rawValue
        }
        
        // Save to health vitals
        await saveHealthVitals()
        
        // Note: This will trigger SmartGoalsService to refresh and generate new recommendations
        // when the view appears or when explicitly called
    }
    
    func updateGender(_ gender: String) async {
        profileData.gender = gender
        await saveHealthVitals()
    }
    
    func updateDateOfBirth(_ dob: String) async {
        profileData.dob = dob
        await saveHealthVitals()
    }
    
    func updateFullName(firstName: String, lastName: String) async {
        self.profileData.firstName = firstName
        self.profileData.lastName = lastName
        await savePersonalData()
    }
    
    func updateEmail(_ email: String) async {
        self.profileData.email = email
        await savePersonalData()
    }
    
    // MARK: - Goal Management
    
    func updateStepGoal(_ goal: Int) async {
        profileData.stepGoal = goal
        await saveGoals()
        // Refresh smart goals to use new step goal
        await smartGoalsService.forceRefreshDailyActions()
    }
    
    func updateWaterGoal(_ goal: Float) async {
        profileData.waterGoal = goal
        await saveGoals()
        // Refresh smart goals to use new water goal
        await smartGoalsService.forceRefreshDailyActions()
    }
    
    func updateCalorieGoal(_ goal: Int) async {
        profileData.calorieGoal = goal
        await saveGoals()
        // Refresh smart goals to use new calorie goal
        await smartGoalsService.forceRefreshDailyActions()
    }
    
    func updateMealGoal(_ goal: Int) async {
        profileData.mealGoal = goal
        await saveGoals()
        // Refresh smart goals to use new meal goal
        await smartGoalsService.forceRefreshDailyActions()
    }
    
    func updateSleepGoal(_ goal: Float) async {
        profileData.sleepGoal = goal
        await saveGoals()
        // Refresh smart goals to use new sleep goal
        await smartGoalsService.forceRefreshDailyActions()
    }
    
    func toggleNotifications() {
        self.profileData.notificationsEnabled.toggle()
        // TODO: Implement actual notification toggle with system
        self.logger.debug("Notifications toggled to: \(self.profileData.notificationsEnabled)")
        self.objectWillChange.send()
    }
    
    func logHealthKitPermissions() async {
        await healthService.logPermissionStatus()
    }
    
    func updateSmartGoals(
        category: LifeGoalCategory,
        type: LifeGoalType,
        timeline: GoalTimeline,
        commitment: GoalCommitmentLevel
    ) async {
        guard let userId = authRepository.authState.userId else {
            uiMessage = "User ID not found"
            return
        }
        
        do {
            let goalData: [String: Any] = [
                "lifeGoalCategory": category.rawValue,
                "lifeGoalType": type.rawValue,
                "goalTimeline": timeline.rawValue,
                "goalCommitmentLevel": commitment.rawValue,
                "goalStartDate": DateFormatter.yyyyMMdd.string(from: Date()),
                "goalProgressPercentage": 0.0
            ]
            
            let _ = try await strapiRepository.updateUser(userId: userId, data: goalData)
            
                                // Update local profile data
                    profileData.lifeGoalCategory = category.rawValue
                    profileData.lifeGoalType = type.rawValue
                    profileData.goalTimeline = timeline.rawValue
                    profileData.goalCommitmentLevel = commitment.rawValue
            profileData.goalStartDate = DateFormatter.yyyyMMdd.string(from: Date())
            profileData.goalProgressPercentage = 0.0
            
            // Refresh smart goals service
            await smartGoalsService.forceRefreshDailyActions()
            
            uiMessage = "Smart goals updated successfully"
            logger.debug("Updated smart goals for user \(userId)")
            objectWillChange.send()
        } catch {
            let errorMessage = "Failed to update smart goals: \(error.localizedDescription)"
            uiMessage = errorMessage
            logger.error("\(errorMessage)")
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
    
    func updatePersonalInfo(
        firstName: String?,
        lastName: String?,
        email: String?,
        dob: String?
    ) async {
        guard let userId = authRepository.authState.userId else {
            uiMessage = "User ID not found"
            return
        }
        
        do {
            let personalData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "dob": dob
            ].compactMapValues { $0 }
            
            let _ = try await strapiRepository.updateUser(userId: userId, data: personalData)
            
            // Update local profile data
            profileData.firstName = firstName
            profileData.lastName = lastName
            profileData.email = email
            profileData.dob = dob
            
            uiMessage = "Personal information updated successfully"
            logger.debug("Updated personal info for user \(userId)")
            objectWillChange.send()
        } catch {
            let errorMessage = "Failed to update personal information: \(error.localizedDescription)"
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

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
