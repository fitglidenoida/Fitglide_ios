//
//  WorkoutViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import HealthKit

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workoutData: WorkoutUiData
    @Published var stepGoal: Float = 10000 // Default step goal
    @Published var stressScore: Int = 0
    @Published var maxHeartRate: Float = 200 // Default max HR
    @Published var availableExercises: [ExerciseEntry] = []
    @Published var completedWorkouts: [WorkoutLogEntry] = []
    @Published var isSyncing = false
    @Published var syncMessage = ""
    
    private let strapiRepository: StrapiRepository
    private let healthService: HealthService
    private let authRepository: AuthRepository
    private var workoutService: WorkoutService!
    
    private var lastFetchDate: Date?
    private var isFetching = false
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    init(strapiRepository: StrapiRepository, healthService: HealthService, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.healthService = healthService
        self.authRepository = authRepository
        // Initialize workoutService on main actor
        self.workoutService = WorkoutService(
            healthService: healthService,
            strapiRepository: strapiRepository,
            authRepository: authRepository
        )
        self.workoutData = WorkoutUiData(
            steps: 0,
            heartRate: 0,
            caloriesBurned: 0,
            selectedGoal: "Cardio",
            schedule: [],
            plans: [],
            insights: [],
            streak: 0
        )
    }
    
    func setDate(_ date: Date) {
        Task {
            do {
                await MainActor.run {
                    isSyncing = true
                    syncMessage = "Loading workout data..."
                }
                
                let dateStr = isoFormatter.string(from: Calendar.current.startOfDay(for: date))

                // Step 1: Try to fetch data from Strapi first
                let strapiWorkouts = try await workoutService.getWorkoutLogs(for: date)
                
                // Also check if health data exists in Strapi
                let healthLog = try? await strapiRepository.getHealthLog(date: dateStr, source: "HealthKit")
                let hasHealthData = healthLog?.data.first != nil
                
                if !strapiWorkouts.isEmpty && hasHealthData {
                    // Both workout and health data exist in Strapi, use it
                    await MainActor.run {
                        syncMessage = "Loading from Strapi..."
                    }
                    
                    await loadDataFromStrapi(date: date, strapiWorkouts: strapiWorkouts)
                } else {
                    // Missing either workout or health data, sync from HealthKit
                    await MainActor.run {
                        syncMessage = "Syncing health data from HealthKit..."
                    }
                    
                    // Sync health data (steps, calories, heart rate)
                    let hkSteps = try await healthService.getSteps(date: date)
                    let heartRate = try await healthService.getHeartRate(date: date)
                    let calories = try await healthService.getCaloriesBurned(date: date)
                    
                    await saveHealthData(
                        steps: Double(hkSteps),
                        calories: Double(calories),
                        heartRate: Double(heartRate.average),
                        date: date
                    )
                    
                    if !strapiWorkouts.isEmpty {
                        // Only health data was missing, now load from Strapi
                        await loadDataFromStrapi(date: date, strapiWorkouts: strapiWorkouts)
                    } else {
                        // Check for workouts in HealthKit
                        await MainActor.run {
                            syncMessage = "Checking HealthKit for workouts..."
                        }
                        
                        // Step 2: Check if there are workouts in HealthKit
                        let healthKitWorkout = try await healthService.getWorkout(date: date)
                        
                        if let _ = healthKitWorkout.start,
                           let _ = healthKitWorkout.end,
                           let workoutType = healthKitWorkout.type,
                           !workoutType.isEmpty {
                            
                            // Step 3: Found workout in HealthKit, sync to Strapi
                            await MainActor.run {
                                syncMessage = "Syncing workout to Strapi..."
                            }
                            
                            try await workoutService.syncHealthKitWorkouts(for: date)
                            
                            // Step 4: Fetch the synced data from Strapi
                            await MainActor.run {
                                syncMessage = "Loading synced data..."
                            }
                            
                            let syncedWorkouts = try await workoutService.getWorkoutLogs(for: date)
                            await loadDataFromStrapi(date: date, strapiWorkouts: syncedWorkouts)
                            
                        } else {
                            // No workouts in HealthKit either, load empty state
                            await MainActor.run {
                                syncMessage = "No workouts found..."
                            }
                            
                            await loadEmptyState(date: date)
                        }
                    }
                }

                
                await MainActor.run {
                    isSyncing = false
                    syncMessage = ""
                }
                
            } catch {
                await MainActor.run {
                    isSyncing = false
                    syncMessage = "❌ Error: \(error.localizedDescription)"
                }
                print("❌ WorkoutViewModel: Failed to load data for \(date): \(error)")
            }
        }
    }
    
    private func loadDataFromStrapi(date: Date, strapiWorkouts: [WorkoutLogEntry]) async {
        let userId = authRepository.authState.userId ?? ""
        let dateStr = isoFormatter.string(from: Calendar.current.startOfDay(for: date))
        
        // Fetch health data from Strapi
        let healthLog = try? await strapiRepository.getHealthLog(date: dateStr, source: "HealthKit")
        let strapiSteps = Float(healthLog?.data.first?.steps ?? 0)
        let strapiHeartRate = Float(healthLog?.data.first?.heartRate ?? 0)
        let strapiCalories = Float(healthLog?.data.first?.caloriesBurned ?? 0)
        
        // Fetch plans
        let plans = try? await strapiRepository.getWorkoutPlans(userId: userId)
        
        await MainActor.run {
            // Populate completed workouts
            self.completedWorkouts = strapiWorkouts.filter { $0.completed }
            
            // Create schedule from workout logs
            let schedule = strapiWorkouts.map { log in
                WorkoutSlot(
                    id: log.documentId,
                    date: isoFormatter.date(from: log.startTime) ?? date,
                    type: log.type ?? "Unknown",
                    time: log.totalTime.map { "\($0) min" } ?? "0 min",
                    moves: [],
                    isCompleted: log.completed
                )
            }
            
            // Create plans
            let workoutPlans = plans?.data.map { plan in
                WorkoutSlot(
                    id: plan.documentId,
                    date: date,
                    type: plan.sportType,
                    time: "\(plan.totalTimePlanned) min",
                    moves: plan.exercises?.map {
                        WorkoutMove(
                            name: $0.name ?? "Unknown",
                            repsOrTime: $0.reps.map { "\($0) reps" } ?? ($0.duration.map { "\($0) min" } ?? ""),
                            sets: $0.sets ?? 1,
                            isCompleted: false,
                            imageUrl: nil,
                            instructions: nil
                        )
                    } ?? [],
                    isCompleted: plan.completed
                )
            } ?? []
            
            self.workoutData = WorkoutUiData(
                steps: strapiSteps,
                heartRate: strapiHeartRate,
                caloriesBurned: strapiCalories,
                selectedGoal: self.workoutData.selectedGoal,
                schedule: schedule,
                plans: workoutPlans,
                insights: generateInsights(
                    steps: Double(strapiSteps),
                    calories: Double(strapiCalories),
                    heartRate: Double(strapiHeartRate)
                ),
                streak: calculateStreak(schedule: schedule)
            )
        }
    }
    
    private func loadEmptyState(date: Date) async {
        let userId = authRepository.authState.userId ?? ""
        
        // Fetch plans even if no workouts
        let plans = try? await strapiRepository.getWorkoutPlans(userId: userId)
        
        await MainActor.run {
            self.completedWorkouts = []
            
            let workoutPlans = plans?.data.map { plan in
                WorkoutSlot(
                    id: plan.documentId,
                    date: date,
                    type: plan.sportType,
                    time: "\(plan.totalTimePlanned) min",
                    moves: plan.exercises?.map {
                        WorkoutMove(
                            name: $0.name ?? "Unknown",
                            repsOrTime: $0.reps.map { "\($0) reps" } ?? ($0.duration.map { "\($0) min" } ?? ""),
                            sets: $0.sets ?? 1,
                            isCompleted: false,
                            imageUrl: nil,
                            instructions: nil
                        )
                    } ?? [],
                    isCompleted: plan.completed
                )
            } ?? []
            
            self.workoutData = WorkoutUiData(
                steps: 0,
                heartRate: 0,
                caloriesBurned: 0,
                selectedGoal: self.workoutData.selectedGoal,
                schedule: [],
                plans: workoutPlans,
                insights: [],
                streak: 0
            )
        }
    }
    
    func fetchWorkoutData(for date: Date = Date()) async {
        guard !isFetching else {
            print("WorkoutViewModel: Skipping fetch because already fetching")
            return
        }
        isFetching = true
        
        // Use the new setDate pattern instead of performFetch
        setDate(date)
        // Also fetch completed workouts for the past week
        await fetchCompletedWorkouts(for: date)
        
        isFetching = false
    }
    
    private func fetchCompletedWorkouts(for date: Date) async {
        do {
            let userId = authRepository.authState.userId ?? ""
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: date) ?? date
            
            // Fetch completed workouts for the past week
            let startDate = isoFormatter.string(from: calendar.startOfDay(for: weekAgo))
            
            let response = try await strapiRepository.getWorkoutLogs(userId: userId, date: startDate)
            let completedWorkouts = response.data.filter { $0.completed }
            
            await MainActor.run {
                self.completedWorkouts = completedWorkouts
            }
        } catch {
            print("WorkoutViewModel: Failed to fetch completed workouts: \(error)")
        }
    }
    


    private func saveHealthData(steps: Double, calories: Double, heartRate: Double, date: Date) async {
        do {
            let dateStr = isoFormatter.string(from: Calendar.current.startOfDay(for: date))
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)!

            let existingLog = try await strapiRepository.getHealthLog(date: dateStr, source: "HealthKit")
            let log = existingLog.data.first

            let finalSteps = Int64(steps)
            let finalCalories = Float(calories)
            let finalHeartRate = Int64(heartRate)

            // Upload health summary
            _ = try await strapiRepository.syncHealthLog(
                date: dateStr,
                steps: finalSteps,
                hydration: 0.0,
                heartRate: finalHeartRate,
                caloriesBurned: finalCalories,
                source: "HealthKit",
                documentId: log?.documentId
            )

            print("✅ Synced health log to Strapi → steps: \(finalSteps)")

            // Upload session summary
            let distance = try await healthService.getDistanceWalked(date: date)

            let isoStart = isoFormatter.string(from: startOfDay)
            let existingSessions = try await strapiRepository.getStepSessions(startTime: isoStart)

            let sumSteps = existingSessions.data.reduce(0) { $0 + $1.steps }
            let sumCalories = existingSessions.data.reduce(0.0) { $0 + $1.caloriesBurned }
            let sumDistance = existingSessions.data.reduce(0.0) { $0 + $1.distance }

            let incrementSteps = Int(steps) - sumSteps
            let incrementCalories = Float(calories) - sumCalories
            let incrementDistance = Float(distance) - sumDistance

            if incrementSteps > 0 {
                let sessionHR = Int(heartRate)

                let sessionResponse = try await strapiRepository.postStepSession(
                    startTime: startOfDay,
                    endTime: endOfDay,
                    steps: incrementSteps,
                    caloriesBurned: incrementCalories,
                    distance: incrementDistance,
                    heartRateAvg: sessionHR,
                    source: "HealthKit",
                    tag: "incremental-auto"
                )
                print("✅ Synced incremental step session → \(sessionResponse)")
            } else {
                print("No increment in steps, skipping step session post")
            }
        } catch {
            print("WorkoutViewModel: Failed to sync health log or step session: \(error)")
        }
    }

    func saveWorkoutLog(slot: WorkoutSlot) async {
        guard let userId = authRepository.authState.userId else {
            print("WorkoutViewModel: No user ID for saving workout log")
            return
        }
        
        let startTime = isoFormatter.string(from: slot.date)
        let endTime = isoFormatter.string(from: Calendar.current.date(byAdding: .minute, value: Int(slot.time.components(separatedBy: " ").first ?? "0") ?? 0, to: slot.date) ?? slot.date)
        
        _ = WorkoutLogRequest(
            logId: slot.id,
            startTime: startTime,
            endTime: endTime,
            distance: 0.0,
            totalTime: Float(slot.time.components(separatedBy: " ").first ?? "0") ?? 0.0,
            calories: workoutData.caloriesBurned,
            heartRateAverage: Int64(workoutData.heartRate),
            heartRateMaximum: Int64(maxHeartRate),
            heartRateMinimum: 0,
            route: [],
            completed: slot.isCompleted,
            notes: slot.type,
            usersPermissionsUser: UserId(id: userId),
            movingTime: nil,
            stravaActivityId: nil,
            athleteId: nil,
            source: "Manual"
        )
        
        // Error handling inside Task
        Task {
            do {
                let response = try await strapiRepository.createWorkoutLog(
                    workoutId: slot.id,
                    type: slot.type,
                    startTime: startTime,
                    userId: userId
                )
                print("WorkoutViewModel: Created workout log: \(response)")
                await fetchWorkoutData(for: slot.date)
            } catch {
                print("WorkoutViewModel: Failed to create workout log: \(error)")
            }
        }
    }
    
    func startWorkout(_ slotId: String, friendIds: [String], completion: @escaping (Bool, String) -> Void) {
        Task {
            if var slot = workoutData.schedule.first(where: { $0.id == slotId }) {
                slot.isCompleted = true
                await saveWorkoutLog(slot: slot)
                await MainActor.run {
                    completion(true, "Workout started successfully!")
                }
            } else {
                await MainActor.run {
                    completion(false, "Workout slot not found")
                }
            }
        }
    }

    func toggleMove(slotId: String, moveIndex: Int) {
        if var slot = workoutData.schedule.first(where: { $0.id == slotId }) {
            slot.moves[moveIndex].isCompleted.toggle()
            workoutData.schedule = workoutData.schedule.map { $0.id == slotId ? slot : $0 }
            Task {
                await saveWorkoutLog(slot: slot)
            }
        }
    }
    
    func createWorkout(title: String, type: String, duration: Float, distance: Float, description: String, exerciseInputs: [ExerciseInput], isTemplate: Bool, date: Date) {
        let moves = exerciseInputs.map { input in
            WorkoutMove(
                name: input.exerciseName,
                repsOrTime: "\(input.reps) reps",
                sets: input.sets,
                isCompleted: false,
                imageUrl: nil,
                instructions: nil
            )
        }
        let slot = WorkoutSlot(id: UUID().uuidString, date: date, type: type, time: "\(Int(duration)) min", moves: moves, isCompleted: false)
        workoutData.plans.append(slot)
        Task {
            do {
                let workoutId = "workout_\(UUID().uuidString)"
                let exerciseIds = exerciseInputs.map { ExerciseId(id: $0.exerciseId) }
                let exerciseOrder = exerciseInputs.map { $0.exerciseId }
                let caloriesPlanned: Float = 0
                _ = try await strapiRepository.syncWorkoutPlan(
                    workoutId: workoutId,
                    title: title,
                    description: description,
                    distancePlanned: distance,
                    totalTimePlanned: duration,
                    caloriesPlanned: caloriesPlanned,
                    sportType: type,
                    exercises: exerciseIds,
                    exerciseOrder: exerciseOrder,
                    isTemplate: isTemplate
                )
                await fetchWorkoutData(for: date)
            } catch {
                print("Failed to sync workout plan: \(error)")
            }
        }
    }
    
    func createWorkoutPlan(
        planId: String,
        planName: String,
        planDescription: String,
        planDurationWeeks: Int,
        planLevel: String,
        planCategory: String,
        planDifficultyRating: Double,
        estimatedCaloriesPerWeek: Float?,
        isPremium: Bool,
        premiumTier: String,
        weekNumber: Int,
        dayNumber: Int,
        title: String,
        type: String,
        duration: Float,
        distance: Float,
        description: String,
        exerciseInputs: [ExerciseInput],
        date: Date
    ) {
        let moves = exerciseInputs.map { input in
            WorkoutMove(
                name: input.exerciseName,
                repsOrTime: "\(input.reps) reps",
                sets: input.sets,
                isCompleted: false,
                imageUrl: nil,
                instructions: nil
            )
        }
        let slot = WorkoutSlot(id: UUID().uuidString, date: date, type: type, time: "\(Int(duration)) min", moves: moves, isCompleted: false)
        workoutData.plans.append(slot)
        
        Task {
            do {
                let workoutId = "\(planId)_week\(weekNumber)_day\(dayNumber)"
                let exerciseIds = exerciseInputs.map { ExerciseId(id: $0.exerciseId) }
                let exerciseOrder = exerciseInputs.map { $0.exerciseId }
                let caloriesPlanned: Float = Float(estimatedCaloriesPerWeek ?? 0) / 7.0 // Daily calories
                
                _ = try await strapiRepository.syncWorkoutPlan(
                    workoutId: workoutId,
                    title: title,
                    description: description,
                    distancePlanned: distance,
                    totalTimePlanned: duration,
                    caloriesPlanned: caloriesPlanned,
                    sportType: type,
                    exercises: exerciseIds,
                    exerciseOrder: exerciseOrder,
                    isTemplate: true,
                    planName: planName,
                    planDescription: planDescription,
                    planDurationWeeks: planDurationWeeks,
                    planLevel: planLevel,
                    planCategory: planCategory,
                    dayNumber: dayNumber,
                    weekNumber: weekNumber,
                    restDay: false,
                    isPremium: isPremium,
                    premiumTier: premiumTier,
                    planDifficultyRating: Float(planDifficultyRating),
                    estimatedCaloriesPerWeek: estimatedCaloriesPerWeek
                )
                await fetchWorkoutData(for: date)
            } catch {
                print("Failed to sync workout plan: \(error)")
            }
        }
    }
    
    func fetchExercises() async {
        do {
            let response = try await strapiRepository.getExercises()
            await MainActor.run {
                self.availableExercises = response.data
            }
        } catch {
            print("Failed to fetch exercises: \(error)")
        }
    }
    
    private func generateInsights(steps: Double, calories: Double, heartRate: Double) -> [String] {
        var insights: [String] = []
        if steps < 5000 {
            insights.append("Try to increase your daily steps to meet your goal!")
        }
        if calories > 500 {
            insights.append("Great job burning calories today!")
        }
        if heartRate > 140 {
            insights.append("High heart rate detected. Consider a lighter workout tomorrow.")
        }
        return insights
    }
    
    private func calculateStreak(schedule: [WorkoutSlot]) -> Int {
        return schedule.filter { $0.isCompleted }.count
    }
    
    // MARK: - Manual Sync Functions
    func manualWorkoutSync() async {
        do {
            print("🔄 Starting manual workout sync...")
            try await workoutService.manualWorkoutSync(for: Date())
            print("✅ Manual workout sync completed")
            
            // Refresh the current data after sync
            await fetchWorkoutData(for: Date())
        } catch {
            print("❌ Manual workout sync failed: \(error)")
        }
    }
    
    func syncStravaWorkouts() async {
        do {
            print("🔄 Syncing Strava workouts...")
            try await workoutService.syncStravaWorkouts()
            print("✅ Strava workout sync completed")
            
            // Check for workout achievements
            let workoutCount = completedWorkouts.count
            AchievementManager.shared.checkWorkoutAchievements(workoutCount: workoutCount, workoutType: "strava")
            
            // Refresh the current data after sync
            await fetchWorkoutData(for: Date())
        } catch {
            print("❌ Strava workout sync failed: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchData(for date: Date = Date()) {
        Task {
            setDate(date)
        }
    }
    
    func syncHistoricalWorkouts() {
        Task {
            do {
                await MainActor.run {
                    isSyncing = true
                    syncMessage = "Checking for unsynced workouts..."
                }
                
                // Check for unsynced workouts in the last 30 days
                let calendar = Calendar.current
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                
                let unsyncedDates = try await workoutService.checkForUnsyncedWorkouts(from: thirtyDaysAgo, to: Date())
                
                if unsyncedDates.isEmpty {
                    await MainActor.run {
                        isSyncing = false
                        syncMessage = "✅ All workouts are already synced!"
                    }
                    return
                }
                
                await MainActor.run {
                    syncMessage = "Found \(unsyncedDates.count) unsynced workouts. Syncing..."
                }
                
                // Sync only the dates that have unsynced workouts
                for date in unsyncedDates {
                    await MainActor.run {
                        syncMessage = "Syncing workout for \(date.formatted(date: .abbreviated, time: .omitted))..."
                    }
                    try await workoutService.syncHealthKitWorkouts(for: date)
                }
                
                await MainActor.run {
                    syncMessage = "Refreshing data..."
                }
                
                // Refresh the current data after sync
                setDate(Date())
                
                // Check for workout achievements after sync
                let workoutCount = completedWorkouts.count
                AchievementManager.shared.checkWorkoutAchievements(workoutCount: workoutCount, workoutType: "historical")
                
                await MainActor.run {
                    isSyncing = false
                    syncMessage = "✅ Sync completed! Synced \(unsyncedDates.count) workouts."
                }
                
                print("✅ Historical workout sync completed for \(unsyncedDates.count) dates")
            } catch {
                await MainActor.run {
                    isSyncing = false
                    syncMessage = "❌ Sync failed: \(error.localizedDescription)"
                }
                print("❌ Historical workout sync failed: \(error)")
            }
        }
    }
}

struct WorkoutUiData {
    var steps: Float
    var heartRate: Float
    var caloriesBurned: Float
    var selectedGoal: String
    var schedule: [WorkoutSlot]
    var plans: [WorkoutSlot]
    var insights: [String]
    var streak: Int
}

struct WorkoutSlot: Identifiable {
    let id: String
    let date: Date
    let type: String
    let time: String
    var moves: [WorkoutMove]
    var isCompleted: Bool
}

struct WorkoutMove {
    let name: String
    let repsOrTime: String
    let sets: Int
    var isCompleted: Bool
    let imageUrl: String?
    let instructions: String?
}

// Extensions
extension Array where Element == Float {
    var average: Float? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Float(count)
    }
}

extension Float? {
    var nonZeroOrNil: Float? {
        self != 0 ? self : nil
    }
}

extension String {
    var nonEmptyOrNil: String? {
        isEmpty ? nil : self
    }
}
