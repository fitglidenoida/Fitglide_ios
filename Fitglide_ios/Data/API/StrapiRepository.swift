//
//  StrapiRepository.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/06/25.
//

import Foundation
import Combine
import HealthKit

class StrapiRepository: ObservableObject {
    private let api: StrapiApi
    private let authRepository: AuthRepository
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    init(api: StrapiApi = StrapiApiClient(), authRepository: AuthRepository) {
        self.api = api
        self.authRepository = authRepository
    }
    
    // MARK: - Health Logs
    func syncHealthLog(
        date: String,
        steps: Int64,
        hydration: Float,
        heartRate: Int64?,
        caloriesBurned: Float?,
        source: String,
        documentId: String? = nil
    ) async throws -> HealthLogResponse {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }

        print("syncHealthLog called with documentId: \(documentId ?? "nil")")

        let requestBody = HealthLogBody(data: HealthLogRequest(
            dateTime: date,
            steps: steps,
            waterIntake: hydration,
            heartRate: heartRate,
            caloriesBurned: caloriesBurned,
            source: source,
            usersPermissionsUser: UserId(id: userId)
        ))

        if let id = documentId {
            print("Updating existing health log: \(id)")
            return try await api.updateHealthLog(id: id, body: requestBody, token: token)
        } else {
            print("Posting new health log")
            return try await api.postHealthLog(body: requestBody, token: token)
        }
    }

    func getHealthLog(date: String, source: String?) async throws -> HealthLogListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        var filters: [String: String] = ["filters[dateTime][$eq]": date]
        if let source = source {
            filters["filters[source][$eq]"] = source
        }
        print("Fetching health log with filters: \(filters)")
        return try await api.getHealthLog(filters: filters, token: token)
    }
    
    // MARK: - Sleep Logs
    func syncSleepLog(date: Date, sleepData: HealthService.SleepData) async -> Result<SleepLogResponse, Error> {
        do {
            guard let userId = authRepository.authState.userId, let token = authRepository.authState.jwt else {
                return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"]))
            }
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let isoDate = isoFormatter.string(from: startOfDay)
            let request = SleepLogRequest(
                date: isoDate,
                sleepDuration: Float(sleepData.total) / 3600.0, // Convert seconds to hours
                deepSleepDuration: Float(sleepData.deep) / 3600.0,
                remSleepDuration: Float(sleepData.rem) / 3600.0,
                lightSleepDuration: Float(sleepData.light) / 3600.0,
                sleepAwakeDuration: Float(sleepData.awake) / 3600.0,
                startTime: isoFormatter.string(from: sleepData.start),
                endTime: isoFormatter.string(from: sleepData.end),
                usersPermissionsUser: UserId(id: userId)
            )
            
            print("Syncing sleep log: date=\(request.date), total=\(request.sleepDuration)h, light=\(request.lightSleepDuration)h, deep=\(request.deepSleepDuration)h, rem=\(request.remSleepDuration)h, awake=\(request.sleepAwakeDuration)h, start=\(request.startTime ?? "nil"), end=\(request.endTime ?? "nil"), userId=\(userId)")
            print("Full request body: \(request)")
            let existingLogs = try await fetchSleepLog(date: date)
            print("Fetched \(existingLogs.data.count) existing sleep logs for \(isoDate)")
            if !existingLogs.data.isEmpty {
                let documentId = existingLogs.data.first!.documentId
                print("Updating existing sleep log: \(documentId)")
                let response = try await api.updateSleepLog(id: documentId, body: request, token: token)
                print("Update response: \(response)")
                return .success(response)
            } else {
                print("Posting new sleep log")
                let response = try await api.postSleepLog(body: request, token: token)
                print("Post response: \(response)")
                return .success(response)
            }
        } catch {
            print("Error syncing sleep log: \(error)")
            return .failure(error)
        }
    }
    
    func fetchSleepLog(date: Date) async throws -> SleepLogListResponse {
        guard let userId = authRepository.authState.userId, let token = authRepository.authState.jwt else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
            print("Fetch error: \(error)")
            throw error
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Ensure ISO formatter uses UTC
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let startIso = isoFormatter.string(from: startOfDay)
        let endIso = isoFormatter.string(from: endOfDay)
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "filters[date][$gte]": startIso,
            "filters[date][$lt]": endIso
        ]
        print("Fetching sleep log for date range: \(startIso) to \(endIso) with filters: \(filters)")
        let response = try await api.getSleepLog(filters: filters, token: token)
        print("Fetched sleep logs: \(response.data)")
        return response
    }
    
    // MARK: - Workouts (Plans)
    func syncWorkoutPlan(
        workoutId: String,
        title: String,
        description: String?,
        distancePlanned: Float,
        totalTimePlanned: Float,
        caloriesPlanned: Float,
        sportType: String,
        exercises: [ExerciseId],
        exerciseOrder: [String],
        isTemplate: Bool,
        // New plan-related parameters
        planName: String? = nil,
        planDescription: String? = nil,
        planDurationWeeks: Int? = nil,
        planLevel: String? = nil,
        planCategory: String? = nil,
        dayNumber: Int? = nil,
        weekNumber: Int? = nil,
        restDay: Bool? = nil,
        isPremium: Bool? = nil,
        premiumTier: String? = nil,
        planDifficultyRating: Float? = nil,
        estimatedCaloriesPerWeek: Float? = nil,
        planStartDate: String? = nil,
        planCompletionPercentage: Float? = nil,
        currentWeek: Int? = nil,
        currentDay: Int? = nil
    ) async throws -> WorkoutResponse {
        guard let _ = authRepository.authState.userId, let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        print("Syncing workout plan via API")
        return try await api.syncWorkoutPlan(
            workoutId: workoutId,
            title: title,
            description: description,
            distancePlanned: distancePlanned,
            totalTimePlanned: totalTimePlanned,
            caloriesPlanned: caloriesPlanned,
            sportType: sportType,
            exercises: exercises,
            exerciseOrder: exerciseOrder,
            isTemplate: isTemplate,
            planName: planName,
            planDescription: planDescription,
            planDurationWeeks: planDurationWeeks,
            planLevel: planLevel,
            planCategory: planCategory,
            dayNumber: dayNumber,
            weekNumber: weekNumber,
            restDay: restDay,
            isPremium: isPremium,
            premiumTier: premiumTier,
            planDifficultyRating: planDifficultyRating,
            estimatedCaloriesPerWeek: estimatedCaloriesPerWeek,
            planStartDate: planStartDate,
            planCompletionPercentage: planCompletionPercentage,
            currentWeek: currentWeek,
            currentDay: currentDay,
            token: token
        )
    }
    
    func getWorkoutPlans(userId: String) async throws -> WorkoutListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "populate": "exercises"
        ]
        print("Fetching workout plans with filters: \(filters)")
        return try await api.getWorkouts(filters: filters, token: token)
    }
    
    // MARK: - Workout Logs
    func createWorkoutLog(workoutId: String, type: String, startTime: String, userId: String) async throws -> WorkoutLogResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let request = WorkoutLogRequest(
            logId: workoutId,
            type: type,
            startTime: startTime,
            endTime: startTime, // Will be updated when workout completes
            distance: 0,
            totalTime: 0,
            calories: 0,
            heartRateAverage: 0,
            heartRateMaximum: 0,
            heartRateMinimum: 0,
            route: [],
            completed: false,
            notes: nil,
            usersPermissionsUser: UserId(id: userId)
        )
        
        return try await api.postWorkoutLog(body: request, token: token)
    }
    
    func updateWorkoutLog(workoutId: String, distance: Float, duration: Float, calories: Float, heartRateAverage: Int64, route: [[String: Any]]) async throws -> WorkoutLogResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let request = WorkoutLogRequest(
            logId: workoutId,
            type: nil,
            startTime: nil,
            endTime: nil,
            distance: distance,
            totalTime: duration,
            calories: calories,
            heartRateAverage: heartRateAverage,
            heartRateMaximum: heartRateAverage,
            heartRateMinimum: heartRateAverage,
            route: route,
            completed: false,
            notes: nil,
            usersPermissionsUser: nil
        )
        
        return try await api.updateWorkoutLog(documentId: workoutId, body: request, token: token)
    }
    
    func completeWorkoutLog(workoutId: String, endTime: String, distance: Float, duration: Float, calories: Float, heartRateAverage: Int64, route: [[String: Any]]) async throws -> WorkoutLogResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let request = WorkoutLogRequest(
            logId: workoutId,
            type: nil,
            startTime: nil,
            endTime: endTime,
            distance: distance,
            totalTime: duration,
            calories: calories,
            heartRateAverage: heartRateAverage,
            heartRateMaximum: heartRateAverage,
            heartRateMinimum: heartRateAverage,
            route: route,
            completed: true,
            notes: "Workout completed via manual tracking",
            usersPermissionsUser: nil
        )
        
        return try await api.updateWorkoutLog(documentId: workoutId, body: request, token: token)
    }
    
    func getWorkoutLogs(userId: String, date: String) async throws -> WorkoutLogListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "filters[startTime][$gte]": "\(date)T00:00:00.000Z",
            "filters[startTime][$lte]": "\(date)T23:59:59.999Z"
        ]
        print("Fetching workout logs with filters: \(filters)")
        return try await api.getWorkoutLogs(filters: filters, token: token)
    }
    
    // MARK: - Sync Health Data
    func syncHealthKitData(for date: Date) async throws {
        let healthService = await HealthService()
        try await healthService.requestAuthorization()
        
        // Sync Steps
        let steps = try await healthService.getSteps(date: date)
        let stepsResponse = try await syncHealthLog(
            date: isoFormatter.string(from: date),
            steps: steps,
            hydration: 0.0,
            heartRate: nil,
            caloriesBurned: nil,
            source: "HealthKit"
        )
        print("Synced steps: \(stepsResponse)")
        
        // Sync Workouts
        let workout = try await healthService.getWorkout(date: date)
        let request = WorkoutLogRequest(
            logId: UUID().uuidString,
            type: nil,
            startTime: isoFormatter.string(from: workout.start ?? date),
            endTime: isoFormatter.string(from: workout.end ?? date),
            distance: Float(workout.distance ?? 0.0),
            totalTime: Float(workout.duration ?? 0.0),
            calories: Float(workout.calories ?? 0.0),
            heartRateAverage: workout.heartRateAvg ?? 0,
            heartRateMaximum: 0,
            heartRateMinimum: 0,
            route: [],
            completed: true,
            notes: workout.type ?? "",
            usersPermissionsUser: UserId(id: authRepository.authState.userId ?? "")
        )
        let workoutResponse = try await createWorkoutLog(workoutId: request.logId, type: workout.type ?? "", startTime: request.startTime ?? "", userId: authRepository.authState.userId ?? "")
        print("Synced workout: \(workoutResponse)")
        
        // Sync Hydration
        let hydration = try await healthService.getHydration(date: date)
        let hydrationResponse = try await syncHealthLog(
            date: isoFormatter.string(from: date),
            steps: 0,
            hydration: Float(hydration),
            heartRate: nil,
            caloriesBurned: nil,
            source: "HealthKit"
        )
        print("Synced hydration: \(hydrationResponse)")
        
        // Sync Heart Rate
        let heartRate = try await healthService.getHeartRate(date: date)
        let heartRateResponse = try await syncHealthLog(
            date: isoFormatter.string(from: date),
            steps: 0,
            hydration: 0.0,
            heartRate: heartRate.average,
            caloriesBurned: nil,
            source: "HealthKit"
        )
        print("Synced heart rate: \(heartRateResponse)")
        
        // Sync Calories Burned
        let calories = try await healthService.getCaloriesBurned(date: date)
        let caloriesResponse = try await syncHealthLog(
            date: isoFormatter.string(from: date),
            steps: 0,
            hydration: 0.0,
            heartRate: nil,
            caloriesBurned: Float(calories),
            source: "HealthKit"
        )
        print("Synced calories: \(caloriesResponse)")
        
        // Sync Distance Walked
        _ = try await healthService.getDistanceWalked(date: date)
        let distanceResponse = try await syncHealthLog(
            date: isoFormatter.string(from: date),
            steps: 0,
            hydration: 0.0,
            heartRate: nil,
            caloriesBurned: nil,
            source: "HealthKit"
        )
        print("Synced distance: \(distanceResponse)")
        
        // Sync Vitals (Weight, HRV, Blood Oxygen)
        let weight = try await healthService.getWeight()
        let vitalsRequest = HealthVitalsRequest(
            WeightInKilograms: weight.map { Int($0) },
            height: nil,
            gender: nil,
            date_of_birth: nil,
            activity_level: nil,
            weight_loss_goal: nil,
            stepGoal: nil,
            waterGoal: nil,
            calorieGoal: nil,
            mealGoal: nil,
            sleepGoal: nil,
            weight_loss_strategy: nil,
            users_permissions_user: UserId(id: authRepository.authState.userId ?? ""),
            BMI: nil,
            BMR: nil,
            // NEW: Life-Based Goal Fields (nil for health sync)
            life_goal_category: nil,
            life_goal_type: nil,
            goal_timeline: nil,
            goal_commitment_level: nil,
            goal_start_date: nil,
            goal_target_date: nil,
            goal_progress_percentage: nil,
            goal_current_milestone: nil,
            goal_predicted_timeline: nil,
            goal_recommended_activities: nil,
            goal_recommended_nutrition: nil,
            goal_success_probability: nil,
            secondary_goals: nil,
            goal_priority: nil,
            goal_milestones: nil,
            goal_achievements: nil,
            goal_insights: nil,
            goal_recommendations: nil,
            goal_energy_score: nil,
            goal_confidence_score: nil,
            goal_stress_score: nil,
            goal_social_score: nil,
            goal_health_score: nil
        )
        let vitalsResponse = try await postHealthVitals(data: vitalsRequest)
        print("Synced vitals: \(vitalsResponse)")
    }
    
    // MARK: - Weight Loss Stories
    func getWeightLossStories() async throws -> WeightLossStoryListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching weight loss stories")
        return try await api.getWeightLossStories(populate: "users_permissions_user", token: token)
    }
    
    func getWeightLossStoriesForUser(userId: String) async throws -> WeightLossStoryListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching weight loss stories for userId: \(userId)")
        return try await api.getWeightLossStoriesForUser(userId: userId, populate: "users_permissions_user", token: token)
    }
    
    func createWeightLossStory(request: WeightLossStoryRequest) async throws -> WeightLossStoryResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Creating weight loss story: \(request)")
        return try await api.postWeightLossStory(body: request, token: token)
    }
    
    func updateWeightLossStoryVisibility(id: String, visibility: String) async throws -> WeightLossStoryResponse {
        guard let userId = authRepository.authState.userId, let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let request = WeightLossStoryRequest(
            storyId: "",
            thenWeight: 0.0,
            nowWeight: 0.0,
            weightLost: 0.0,
            storyText: "",
            usersPermissionsUser: UserId(id: userId),
            visibility: visibility,
            beforeImage: nil,
            afterImage: nil
        )
        print("Updating visibility for weight loss story: \(id) to \(visibility)")
        return try await api.updateWeightLossStory(id: id, body: request, token: token)
    }
    
    // MARK: - Health Vitals
    func getHealthVitals(userId: String) async throws -> HealthVitalsListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching health vitals for userId: \(userId)")
        return try await api.getHealthVitals(userId: userId, populate: "*", token: token)
    }
    
    func postHealthVitals(data: HealthVitalsRequest) async throws -> HealthVitalsResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting health vitals: \(data)")
        return try await api.postHealthVitals(body: data, token: token)
    }
    
    func updateHealthVitals(documentId: String, data: HealthVitalsRequest) async throws -> HealthVitalsResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating health vitals: \(documentId)")
        return try await api.updateHealthVitals(id: documentId, body: data, token: token)
    }
    
    // MARK: - User Profile
    func getUserProfile() async throws -> UserProfileResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching user profile with token: Bearer \(token.prefix(10))...")
        return try await api.getUserProfile(token: token)
    }
    
    func updateUserProfile(userId: String, data: UserProfileRequest) async throws -> UserProfileResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating user profile for userId: \(userId)")
        return try await api.updateUserProfile(id: userId, body: data, token: token)
    }
    
    func updateUser(userId: String, data: [String: Any]) async throws -> UserProfileResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating user settings for userId: \(userId)")
        
        // Convert dictionary to UserProfileRequest
        let request = UserProfileRequest(
            username: data["username"] as? String ?? data["firstName"] as? String,
            firstName: data["firstName"] as? String,
            lastName: data["lastName"] as? String,
            email: data["email"] as? String,
            mobile: data["mobile"] as? Int64,
            notificationsEnabled: data["notificationsEnabled"] as? Bool,
            maxGreetingsEnabled: data["maxGreetingsEnabled"] as? Bool,
            athleteId: data["athleteId"] as? Int,
            stravaConnected: data["stravaConnected"] as? Bool,
            themePreference: data["themePreference"] as? String
        )
        
        return try await api.updateUserProfile(id: userId, body: request, token: token)
    }
    
    func getBadges(userId: String) async throws -> BadgeListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching badges for userId: \(userId)")
        return try await api.getBadges(populate: "*", token: token)
    }
    
    func joinPack(request: PackJoinRequest) async throws -> PackResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Joining pack: \(request)")
        return try await api.joinPack(request: request, token: token)
    }
    
    func joinChallenge(request: ChallengeJoinRequest) async throws -> ChallengeResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Joining challenge: \(request)")
        return try await api.joinChallenge(request: request, token: token)
    }
    
    // MARK: - Meals and Diet
    func postCustomMealRequest(request: CustomMealRequest) async throws -> CustomMealResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting custom meal request: \(request)")
        return try await api.postCustomMealRequest(body: request, token: token)
    }
    
    func postMealGoal(request: MealGoalRequest) async throws -> MealGoalResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting meal goal: \(request)")
        return try await api.postMealGoal(body: request, token: token)
    }
    
    func getDietPlan(userId: String, date: Date) async throws -> DietPlanListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let dateStr = dateFormatter.string(from: date)     // "yyyy-MM-dd"
        print("Fetching diet plan for userId: \(userId), date: \(dateStr)")
        return try await api.getDietPlan(userId: userId, mealDate: nil, populate: "meals.diet_components", token: token)
    }
    
    func getDietComponents(type: String) async throws -> DietComponentListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        var allComponents: [DietComponentEntry] = []
        var page = 1
        let pageSize = 100
        
        print("Fetching diet components for type: \(type)")
        repeat {
            let response = try await api.getDietComponents(type: type, pageSize: pageSize, page: page, token: token)
            allComponents.append(contentsOf: response.data)
            page += 1
        } while !allComponents.isEmpty && allComponents.count % pageSize == 0
        
        print("Fetched \(allComponents.count) diet components")
        return DietComponentListResponse(data: allComponents)
    }
    
    func postDietPlan(body: DietPlanRequest) async throws -> DietPlanResponse {
        guard let userId = authRepository.authState.userId, let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        print("Posting diet plan: \(body)")
        let existingPlans = try await getDietPlan(userId: userId, date: Date())
        for plan in existingPlans.data where plan.active {
            let updatedPlan = DietPlanRequest(
                planId: plan.planId,
                totalCalories: plan.totalCalories,
                dietPreference: plan.dietPreference,
                active: false,
                pointsEarned: plan.pointsEarned,
                dietGoal: plan.dietGoal,
                meals: plan.meals?.map { $0.documentId } ?? [],
                usersPermissionsUser: UserId(id: userId)
            )
            _ = try await updateDietPlan(documentId: plan.documentId, body: updatedPlan)
        }
        
        return try await api.postDietPlan(body: body, token: token)
    }
    
    func updateDietPlan(documentId: String, body: DietPlanRequest) async throws -> DietPlanResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating diet plan: \(documentId)")
        return try await api.updateDietPlan(documentId: documentId, body: body, token: token)
    }
    
    func postMeal(body: MealRequest) async throws -> MealResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting meal: \(body)")
        return try await api.postMeal(body: body, token: token)
    }
    
    func updateMeal(documentId: String, body: MealRequest) async throws -> MealResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating meal: \(documentId)")
        return try await api.updateMeal(documentId: documentId, body: body, token: token)
    }
    
    func getDietLogs(userId: String, dateString: String) async throws -> DietLogListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let responseData = try await api.getDietLogs(userId: userId, date: dateString, token: token)
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let decodedResponse = try jsonDecoder.decode(DietLogListResponse.self, from: responseData)
        return decodedResponse
    }
    
    func postDietLog(body: DietLogRequest) async throws -> DietLogResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting diet log: \(body)")
        return try await api.postDietLog(body: body, token: token)
    }
    
    func putDietLog(logId: String, request: DietLogUpdateRequest) async throws -> DietLogResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating diet log: \(logId)")
        return try await api.putDietLog(documentId: logId, body: request, token: token)
    }
    
    func postFeedback(request: FeedbackRequest) async throws -> FeedbackResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting feedback: \(request)")
        return try await api.postFeedback(body: request, token: token)
    }
    
    // MARK: - Packs
    func getPacks(userId: String) async throws -> PackListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching packs for userId: \(userId)")
        return try await api.getPacks(userId: userId, token: token)
    }
    
    func postPack(request: PackRequest) async throws -> PackResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting pack: \(request)")
        return try await api.postPack(body: request, token: token)
    }
    
    func updatePack(id: String, request: PackRequest) async throws -> PackResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating pack: \(id)")
        return try await api.updatePack(id: id, body: request, token: token)
    }
    
    // MARK: - Posts
    func getPosts(packId: Int?) async throws -> PostListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching posts for packId: \(packId.map(String.init) ?? "nil")")
        return try await api.getPosts(packId: packId, token: token)
    }
    
    func postPost(request: PostRequest) async throws -> PostResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting post: \(request)")
        return try await api.postPost(body: request, token: token)
    }
    
    // MARK: - Cheers
    func getCheers(userId: String) async throws -> CheerListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching cheers for userId: \(userId)")
        return try await api.getCheers(userId: userId, token: token)
    }
    
    func postCheer(request: CheerRequest) async throws -> CheerResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting cheer: \(request)")
        return try await api.postCheer(body: request, token: token)
    }
    
    // MARK: - Challenges
    func getChallenges(userId: String) async throws -> ChallengeListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching challenges for userId: \(userId)")
        return try await api.getChallenges(userId: userId, token: token)
    }
    
    func getAcceptedChallenges(userId: String) async throws -> ChallengeListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching accepted challenges for userId: \(userId)")
        return try await api.getAcceptedChallenges(userId: userId, token: token)
    }
    
    func postChallenge(request: ChallengeRequest) async throws -> ChallengeResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting challenge: \(request)")
        return try await api.postChallenge(body: request, token: token)
    }
    
    func updateChallenge(id: String, request: ChallengeRequest) async throws -> ChallengeResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating challenge: \(id)")
        return try await api.updateChallenge(id: id, body: request, token: token)
    }
    
    // MARK: - Friends
    func getFriends(filters: [String: String] = [:]) async throws -> FriendListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let adjustedFilters = filters.reduce(into: [String: String]()) { result, pair in
            result[pair.key.replacingOccurrences(of: "[$eq]", with: "")] = pair.value
        }
        print("Fetching friends with filters: \(adjustedFilters)")
        return try await api.getFriends(filters: adjustedFilters, token: token)
    }
    
    func postFriend(request: FriendRequest) async throws -> FriendResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting friend: \(request)")
        return try await api.postFriend(body: request, token: token)
    }
    
    func updateFriend(id: String, request: FriendRequest) async throws -> FriendResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Updating friend: \(id)")
        return try await api.updateFriend(id: id, body: request, token: token)
    }
    
    // MARK: - Comments
    func getComments(postId: String) async throws -> CommentListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching comments for postId: \(postId)")
        return try await api.getComments(postId: postId, token: token)
    }
    
    func postComment(request: CommentRequest) async throws -> CommentListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Posting comment: \(request)")
        return try await api.postComment(body: request, token: token)
    }
    
    // MARK: - Strava Integration
    func initiateStravaAuth(state: String) async throws -> StravaAuthResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Initiating Strava auth with state: \(state)")
        return try await api.initiateStravaAuth(state: state, token: token)
    }
    
    func exchangeStravaCode(code: String) async throws -> StravaTokenResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let request = StravaTokenRequest(code: code)
        print("Exchanging Strava code: \(code)")
        return try await api.exchangeStravaCode(request: request, token: token)
    }
    
    // MARK: - Desi Messages and Badges
    func getDesiMessages() async throws -> DesiMessageResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Fetching desi messages")
        return try await api.getDesiMessages(populate: "*", token: token)
    }
    
    func getExercises() async throws -> ExerciseListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        var allExercises: [ExerciseEntry] = []
        var page = 1
        let pageSize = 100
        
        print("Fetching exercises")
        repeat {
            let response = try await api.getExercises(pageSize: pageSize, page: page, token: token)
            allExercises.append(contentsOf: response.data)
            page += 1
        } while !allExercises.isEmpty && allExercises.count % pageSize == 0
        
        print("Fetched \(allExercises.count) exercises")
        return ExerciseListResponse(data: allExercises)
    }
    
    func uploadFile(file: URL) async throws -> [MediaData] {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Uploading file: \(file.lastPathComponent)")
        return try await api.uploadFile(file: file, token: token)
    }
    
    func syncStepSession(
        startTime: Date,
        endTime: Date,
        steps: Int,
        caloriesBurned: Float,
        distance: Float,
        heartRateAvg: Int,
        source: String,
        tag: String?
    ) async throws -> StepSessionResponse {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }

        let isoStart = isoFormatter.string(from: startTime)
        let isoEnd = isoFormatter.string(from: endTime)

        let request = StepSessionRequest(
            startTime: isoStart,
            endTime: isoEnd,
            steps: steps,
            caloriesBurned: caloriesBurned,
            distance: distance,
            heartRateAvg: heartRateAvg,
            source: source,
            tag: tag,
            usersPermissionsUser: UserId(id: userId)
        )

        print("Syncing step session: \(request)")

        // Check for existing session on the same start time
        let existing = try await getStepSessions(startTime: isoStart)
        if let match = existing.data.first(where: { $0.startTime == isoStart }) {
            print("Updating step session: \(match.documentId)")
            return try await api.updateStepSession(id: match.documentId, body: request, token: token)
        } else {
            print("Posting new step session")
            return try await api.postStepSession(body: request, token: token)
        }
    }
    
    func postStepSession(
        startTime: Date,
        endTime: Date,
        steps: Int,
        caloriesBurned: Float,
        distance: Float,
        heartRateAvg: Int,
        source: String,
        tag: String?
    ) async throws -> StepSessionResponse {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }

        let isoStart = isoFormatter.string(from: startTime)
        let isoEnd = isoFormatter.string(from: endTime)

        let request = StepSessionRequest(
            startTime: isoStart,
            endTime: isoEnd,
            steps: steps,
            caloriesBurned: caloriesBurned,
            distance: distance,
            heartRateAvg: heartRateAvg,
            source: source,
            tag: tag,
            usersPermissionsUser: UserId(id: userId)
        )

        print("🚀 Posting new step session: \(request)")

        return try await api.postStepSession(body: request, token: token)
    }

    func getStepSessions(startTime: String) async throws -> StepSessionListResponse {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }

        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "filters[startTime][$eq]": startTime
        ]

        print("Fetching step sessions with filters: \(filters)")
        return try await api.getStepSessions(filters: filters, token: token)
    }
    
    // MARK: - Period Tracking
    func getPeriods(userId: String) async throws -> PeriodListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "sort": "startDate:desc"
        ]
        
        print("Fetching periods for userId: \(userId)")
        return try await api.getPeriods(filters: filters, token: token)
    }
    
    func syncPeriod(
        startDate: String,
        endDate: String?,
        duration: Int,
        flowIntensity: String,
        cycleDay: Int?,
        cycleLength: Int?,
        symptoms: [String]?,
        notes: String?,
        source: String,
        confidence: Double?,
        isPrediction: Bool,
        predictionAccuracy: Double?,
        healthKitSampleId: String?,
        periodId: String?
    ) async throws -> PeriodResponse {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let request = PeriodRequest(
            periodId: periodId,
            startDate: startDate,
            endDate: endDate ?? "",
            duration: duration,
            flowIntensity: flowIntensity,
            cycleDay: cycleDay ?? 0,
            cycleLength: cycleLength ?? 28,
            symptoms: symptoms,
            notes: notes,
            source: source,
            confidence: confidence,
            isPrediction: isPrediction,
            predictionAccuracy: predictionAccuracy,
            healthKitSampleId: healthKitSampleId,
            users_permissions_user: UserId(id: userId)
        )
        
        print("Syncing period: \(request)")
        
        // Check for existing period with same start date
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "filters[startDate][$eq]": startDate
        ]
        
        let existingPeriods = try await api.getPeriods(filters: filters, token: token)
        
        if let existingPeriod = existingPeriods.data.first {
            print("Updating existing period: \(existingPeriod.documentId)")
            return try await api.updatePeriod(id: existingPeriod.documentId, body: request, token: token)
        } else {
            print("Posting new period")
            return try await api.postPeriod(body: request, token: token)
        }
    }
    
    func deletePeriod(periodId: String) async throws {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Deleting period: \(periodId)")
        try await api.deletePeriod(id: periodId, token: token)
    }
    
    // MARK: - Period Symptoms
    func getPeriodSymptoms(userId: String) async throws -> PeriodSymptomListResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "sort": "date:desc"
        ]
        
        print("Fetching period symptoms for userId: \(userId)")
        return try await api.getPeriodSymptoms(filters: filters, token: token)
    }
    
    func syncPeriodSymptom(
        name: String,
        severity: String,
        date: String,
        time: String?,
        cycleDay: Int?,
        category: String,
        icon: String?,
        notes: String?,
        source: String,
        healthKitSampleId: String?,
        period: Int?,
        symptomId: String?
    ) async throws -> PeriodSymptomResponse {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let request = PeriodSymptomRequest(
            symptomId: symptomId,
            name: name,
            severity: severity,
            date: date,
            time: time,
            cycleDay: cycleDay,
            category: category,
            icon: icon,
            notes: notes,
            source: source,
            healthKitSampleId: healthKitSampleId,
            period: period,
            users_permissions_user: UserId(id: userId)
        )
        
        print("Syncing period symptom: \(request)")
        
        // Check for existing symptom with same name and date
        let filters = [
            "filters[users_permissions_user][id][$eq]": userId,
            "filters[name][$eq]": name,
            "filters[date][$eq]": date
        ]
        
        let existingSymptoms = try await api.getPeriodSymptoms(filters: filters, token: token)
        
        if let existingSymptom = existingSymptoms.data.first {
            print("Updating existing period symptom: \(existingSymptom.documentId)")
            return try await api.updatePeriodSymptom(id: existingSymptom.documentId, body: request, token: token)
        } else {
            print("Posting new period symptom")
            return try await api.postPeriodSymptom(body: request, token: token)
        }
    }
    
    func deletePeriodSymptom(symptomId: String) async throws {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        print("Deleting period symptom: \(symptomId)")
        try await api.deletePeriodSymptom(id: symptomId, token: token)
    }
    
    // MARK: - Live Cheer
    func sendLiveCheer(cheer: LiveCheer) async throws -> LiveCheerResponse {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let request = LiveCheerRequest(
            workoutId: cheer.workoutId,
            fromUserId: cheer.fromUserId,
            message: cheer.message,
            type: cheer.type.rawValue
        )
        
        return try await api.postLiveCheer(body: request, token: token)
    }
    
    func getLiveCheers(workoutId: String) async throws -> [LiveCheer] {
        guard let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
        }
        
        let response = try await api.getLiveCheers(workoutId: workoutId, token: token)
        // Convert LiveCheerEntry to LiveCheer
        return response.data.map { entry in
            LiveCheer(
                id: entry.id,
                workoutId: entry.workoutId,
                fromUserId: entry.fromUserId,
                message: entry.message,
                timestamp: ISO8601DateFormatter().date(from: entry.timestamp) ?? Date(),
                type: LiveCheer.CheerType(rawValue: entry.type) ?? .motivation
            )
        }
    }
    

}
