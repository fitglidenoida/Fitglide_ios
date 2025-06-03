//
//  WorkoutViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import HealthKit

class WorkoutViewModel: ObservableObject {
    @Published var workoutData: WorkoutUiData
    @Published var stepGoal: Float = 10000 // Default step goal
    @Published var stressScore: Int = 0
    @Published var maxHeartRate: Float = 200 // Default max HR
    @Published var availableExercises: [ExerciseEntry] = []
    private let strapiRepository: StrapiRepository
    private let healthService: HealthService
    private let authRepository: AuthRepository
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
        // Synchronous wrapper for async fetch
        Task {
            await fetchWorkoutData(for: date)
        }
    }
    
    func fetchWorkoutData(for date: Date = Date()) async {
        guard !isFetching else {
            print("WorkoutViewModel: Skipping fetch because already fetching")
            return
        }
        isFetching = true
        defer { isFetching = false }

        // Debounce
//        guard lastFetchDate == nil || Calendar.current.dateComponents([.second], from: lastFetchDate!, to: Date()).second! > 10 else {
//            print("WorkoutViewModel: Skipping fetch due to debounce")
//            return
//        }
//        lastFetchDate = Date()

        do {
            let userId = authRepository.authState.userId ?? ""
            let dateStr = isoFormatter.string(from: Calendar.current.startOfDay(for: date))
            let dateOnly = dateStr.components(separatedBy: "T").first ?? ""

            // Fetch data from HealthKit
            let hkSteps = try await healthService.getSteps(date: date) // Assume this method exists in HealthService, returns Double
            let heartRate = try await healthService.getHeartRate(date: date)
            let calories = try await healthService.getCaloriesBurned(date: date)
            let stress = try await healthService.getHRV(date: date)

            // Sync HealthKit data to Strapi
            await saveHealthData(
                steps: Double(hkSteps),
                calories: Double(calories),
                heartRate: Double(heartRate.average),
                date: date
            )

            // Fetch updated log from Strapi
            let updatedLog = try await strapiRepository.getHealthLog(date: dateStr, source: "HealthKit")
            let strapiSteps = Float(updatedLog.data.first?.steps ?? 0)
            let strapiHeartRate = Float(updatedLog.data.first?.heartRate ?? 0)
            let strapiCalories = Float(updatedLog.data.first?.caloriesBurned ?? 0)

            let fetchedStepGoal = try await strapiRepository.getHealthVitals(userId: userId).data.first?.stepGoal ?? 10000

            // Fetch logs + plans
            let plans = try await strapiRepository.getWorkoutPlans(userId: userId)
            let logs = try await strapiRepository.getWorkoutLogs(userId: userId, date: dateOnly)

            let schedule = logs.data.map { log in
                WorkoutSlot(
                    id: log.documentId,
                    date: isoFormatter.date(from: log.startTime) ?? date,
                    type: log.type ?? "Unknown",
                    time: log.totalTime.map { "\($0) min" } ?? "0 min",
                    moves: [],
                    isCompleted: log.completed
                )
            }
            

            await MainActor.run {
                let sdnn = stress?.sdnn ?? 0
                self.stressScore = {
                    switch sdnn {
                    case 60...: return 1 // Low
                    case 30..<60: return 2 // Medium
                    case ..<30: return 3 // High
                    default: return 2
                    }
                }()

                self.workoutData = WorkoutUiData(
                    steps: strapiSteps,
                    heartRate: strapiHeartRate,
                    caloriesBurned: strapiCalories,
                    selectedGoal: self.workoutData.selectedGoal,
                    schedule: schedule,
                    plans: plans.data.map { plan in
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
                    },
                    insights: generateInsights(
                        steps: Double(strapiSteps),
                        calories: Double(strapiCalories),
                        heartRate: Double(strapiHeartRate)
                    ),
                    streak: calculateStreak(schedule: schedule)
                )

                self.stepGoal = Float(fetchedStepGoal)
            }

        } catch {
            print("WorkoutViewModel: Failed to fetch workout data: \(error)")
            await MainActor.run {
                self.workoutData = WorkoutUiData(
                    steps: 0,
                    heartRate: 0,
                    caloriesBurned: 0,
                    selectedGoal: workoutData.selectedGoal,
                    schedule: [],
                    plans: [],
                    insights: ["Error fetching data: \(error.localizedDescription)"],
                    streak: 0
                )
            }
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
        
        let log = WorkoutLogRequest(
            logId: slot.id,
            workout: nil,
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
            usersPermissionsUser: UserId(id: userId)
        )
        
        // Error handling inside Task
        Task {
            do {
                let response = try await strapiRepository.syncWorkoutLog(log: log)
                print("WorkoutViewModel: Synced workout log: \(response)")
                await fetchWorkoutData(for: slot.date)
            } catch {
                print("WorkoutViewModel: Failed to sync workout log: \(error)")
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
