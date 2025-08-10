//
//  WorkoutService.swift
//  Fitglide_ios
//
//  Created by Assistant on 2024.
//

import Foundation
import HealthKit

@MainActor
class WorkoutService: ObservableObject {
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    // MARK: - HealthKit Workout Sync
    func syncHealthKitWorkouts(for date: Date) async throws {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            try await strapiRepository.syncWorkoutWithDeduplication(date: date)
            lastSyncDate = Date()
            print("✅ HealthKit workout sync completed for \(date)")
        } catch {
            syncError = error.localizedDescription
            print("❌ HealthKit workout sync failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Strava Workout Sync
    func syncStravaWorkouts() async throws {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            try await strapiRepository.syncStravaWorkouts()
            lastSyncDate = Date()
            print("✅ Strava workout sync completed")
        } catch {
            syncError = error.localizedDescription
            print("❌ Strava workout sync failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Manual Workout Sync
    func manualWorkoutSync(for date: Date) async throws {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            print("🔄 Starting manual workout sync for \(date)")
            
            // Sync HealthKit workouts
            try await syncHealthKitWorkouts(for: date)
            
            // Sync Strava workouts
            try await syncStravaWorkouts()
            
            lastSyncDate = Date()
            print("✅ Manual workout sync completed for \(date)")
        } catch {
            syncError = error.localizedDescription
            print("❌ Manual workout sync failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Historical Workout Sync
    func syncHistoricalWorkouts(from startDate: Date, to endDate: Date) async throws {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            print("🔄 Starting historical workout sync from \(startDate) to \(endDate)")
            
            let calendar = Calendar.current
            var currentDate = startDate
            
            while currentDate <= endDate {
                print("🔄 Syncing workouts for \(currentDate)")
                try await syncHealthKitWorkouts(for: currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            // Sync Strava workouts once for the entire period
            try await syncStravaWorkouts()
            
            lastSyncDate = Date()
            print("✅ Historical workout sync completed")
        } catch {
            syncError = error.localizedDescription
            print("❌ Historical workout sync failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Workout Data Fetching
    func getWorkoutLogs(for date: Date) async throws -> [WorkoutLogEntry] {
        let userId = authRepository.authState.userId ?? ""
        let dateString = formatDateForAPI(date)
        let response = try await strapiRepository.getWorkoutLogs(userId: userId, date: dateString)
        return response.data
    }
    
    // MARK: - Check for Unsynced Workouts
    func checkForUnsyncedWorkouts(from startDate: Date, to endDate: Date) async throws -> [Date] {
        var datesWithUnsyncedWorkouts: [Date] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            do {
                let workout = try await healthService.getWorkout(date: currentDate)
                
                // Check if there's a valid workout in HealthKit
                if let startTime = workout.start,
                   let endTime = workout.end,
                   let workoutType = workout.type,
                   !workoutType.isEmpty {
                    
                    // Check if this workout exists in Strapi
                    let userId = authRepository.authState.userId ?? ""
                    let dateString = formatDateForAPI(currentDate)
                    let existingWorkouts = try await strapiRepository.getWorkoutLogs(userId: userId, date: dateString)
                    
                    let existsInStrapi = existingWorkouts.data.contains { existing in
                        existing.startTime == formatDateForAPI(startTime) &&
                        existing.type == workoutType
                    }
                    
                    if !existsInStrapi {
                        datesWithUnsyncedWorkouts.append(currentDate)
                        print("🔄 Found unsynced workout on \(currentDate)")
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            } catch {
                print("❌ Error checking workouts for \(currentDate): \(error)")
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return datesWithUnsyncedWorkouts
    }
    
    // MARK: - Workout Creation
    func createWorkoutLog(type: String, startTime: Date) async throws -> WorkoutLogResponse {
        let workoutId = UUID().uuidString
        let startTimeString = formatDateForAPI(startTime)
        let userId = authRepository.authState.userId ?? ""
        
        return try await strapiRepository.createWorkoutLog(
            workoutId: workoutId,
            type: type,
            startTime: startTimeString,
            userId: userId
        )
    }
    
    // MARK: - Workout Completion
    func completeWorkoutLog(
        workoutId: String,
        endTime: Date,
        distance: Float,
        duration: Float,
        calories: Float,
        heartRateAverage: Int64,
        route: [[String: Float]]
    ) async throws -> WorkoutLogResponse {
        let endTimeString = formatDateForAPI(endTime)
        
        return try await strapiRepository.completeWorkoutLog(
            workoutId: workoutId,
            endTime: endTimeString,
            distance: distance,
            duration: duration,
            calories: calories,
            heartRateAverage: heartRateAverage,
            route: route
        )
    }
    
    // MARK: - Workout Updates
    func updateWorkoutLog(
        workoutId: String,
        distance: Float,
        duration: Float,
        calories: Float,
        heartRateAverage: Int64,
        route: [[String: Float]]
    ) async throws -> WorkoutLogResponse {
        return try await strapiRepository.updateWorkoutLog(
            workoutId: workoutId,
            distance: distance,
            duration: duration,
            calories: calories,
            heartRateAverage: heartRateAverage,
            route: route
        )
    }
    
    // MARK: - Helper Functions
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date).components(separatedBy: "T").first ?? ""
    }
    
    // MARK: - Sync Status
    func getSyncStatus() -> String {
        if isSyncing {
            return "Syncing workouts..."
        } else if let error = syncError {
            return "Sync failed: \(error)"
        } else if let lastSync = lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last synced: \(formatter.string(from: lastSync))"
        } else {
            return "No sync history"
        }
    }
}
