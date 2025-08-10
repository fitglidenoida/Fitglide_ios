//
//  ActiveWorkoutManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import HealthKit
import CoreLocation
import Combine

@MainActor
class ActiveWorkoutManager: NSObject, ObservableObject {
    @Published var workoutData = ActiveWorkoutData()
    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var currentLocation: CLLocation?
    @Published var routeCoordinates: [CLLocation] = []
    @Published var workoutId: String?
    
    private var timer: Timer?
    private var startTime: Date?
    private var pauseTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var locationManager: CLLocationManager?
    private var healthService: HealthService
    private var strapiRepository: StrapiRepository
    private var authRepository: AuthRepository
    
    private var workoutType: WorkoutType = .walking
    
    override init() {
        self.healthService = HealthService()
        self.authRepository = AuthRepository()
        self.strapiRepository = StrapiRepository(authRepository: authRepository)
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    func startWorkout(type: WorkoutType) {
        workoutType = type
        workoutId = "workout_\(UUID().uuidString)"
        startTime = Date()
        isWorkoutActive = true
        isPaused = false
        totalPausedTime = 0
        
        // Start location tracking
        startLocationTracking()
        
        // Start timer
        startTimer()
        
        // Create workout log in Strapi
        createWorkoutLog()
        
        // Start real-time sync
        startRealTimeSync()
    }
    
    func stopWorkout() {
        isWorkoutActive = false
        isPaused = false
        
        // Stop timer
        stopTimer()
        
        // Stop location tracking
        stopLocationTracking()
        
        // Complete workout log
        completeWorkoutLog()
        
        // Stop real-time sync
        stopRealTimeSync()
    }
    
    func togglePause() {
        if isPaused {
            resumeWorkout()
        } else {
            pauseWorkout()
        }
    }
    
    func pauseWorkout() {
        isPaused = true
        pauseTime = Date()
        stopTimer()
    }
    
    func resumeWorkout() {
        isPaused = false
        if let pauseTime = pauseTime {
            totalPausedTime += Date().timeIntervalSince(pauseTime)
            self.pauseTime = nil
        }
        startTimer()
    }
    
    func addLap() {
        workoutData.laps.append(LapData(
            number: workoutData.laps.count + 1,
            duration: workoutData.duration,
            distance: workoutData.distance,
            pace: calculatePace()
        ))
    }
    
    // MARK: - Computed Properties
    var formattedDuration: String {
        let duration = workoutData.duration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        if workoutData.distance >= 1000 {
            return String(format: "%.2f km", workoutData.distance / 1000)
        } else {
            return String(format: "%.0f m", workoutData.distance)
        }
    }
    
    var formattedPace: String {
        let pace = calculatePace()
        if pace > 0 {
            let minutes = Int(pace) / 60
            let seconds = Int(pace) % 60
            return String(format: "%d:%02d /km", minutes, seconds)
        } else {
            return "--:-- /km"
        }
    }
    
    var formattedHeartRate: String {
        if workoutData.heartRate > 0 {
            return "\(Int(workoutData.heartRate)) bpm"
        } else {
            return "-- bpm"
        }
    }
    
    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 10 // Update every 10 meters
    }
    
    private func startLocationTracking() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    private func stopLocationTracking() {
        locationManager?.stopUpdatingLocation()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateWorkoutData()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateWorkoutData() {
        guard let startTime = startTime else { return }
        
        let currentTime = Date()
        let elapsedTime = currentTime.timeIntervalSince(startTime) - totalPausedTime
        
        workoutData.duration = elapsedTime
        workoutData.calories = calculateCalories(duration: elapsedTime, distance: workoutData.distance)
        
        // Update heart rate
        Task {
            do {
                let heartRate = try await healthService.getHeartRate(date: currentTime)
                workoutData.heartRate = Double(heartRate.average)
            } catch {
                // Heart rate not available
            }
        }
    }
    
    private func calculatePace() -> Double {
        guard workoutData.distance > 0 else { return 0 }
        return workoutData.duration / (workoutData.distance / 1000) // seconds per km
    }
    
    private func calculateCalories(duration: TimeInterval, distance: Double) -> Double {
        // Basic calorie calculation based on MET values
        let metValue: Double
        switch workoutType {
        case .walking: metValue = 3.5
        case .running: metValue = 8.0
        case .cycling: metValue = 6.0
        case .swimming: metValue = 7.0
        case .strength: metValue = 4.0
        case .yoga: metValue = 2.5
        case .other: metValue = 4.0
        }
        
        // Assume 70kg weight for calculation
        let weight = 70.0
        let caloriesPerMinute = (metValue * weight * 3.5) / 200
        return caloriesPerMinute * (duration / 60)
    }
    
    private func createWorkoutLog() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else { return }
                
                let startTimeString = ISO8601DateFormatter().string(from: startTime ?? Date())
                let workoutLog = try await strapiRepository.createWorkoutLog(
                    workoutId: workoutId ?? "",
                    type: workoutType.rawValue,
                    startTime: startTimeString,
                    userId: userId
                )
                
                print("Created workout log: \(workoutLog.data.documentId)")
            } catch {
                print("Failed to create workout log: \(error)")
            }
        }
    }
    
    private func completeWorkoutLog() {
        Task {
            do {
                guard let workoutId = workoutId else { return }
                
                let endTime = Date()
                let endTimeString = ISO8601DateFormatter().string(from: endTime)
                
                // Convert route coordinates to format expected by Strapi
                let routeData = routeCoordinates.map { location in
                    [
                        "latitude": Float(location.coordinate.latitude),
                        "longitude": Float(location.coordinate.longitude),
                        "timestamp": Float(location.timestamp.timeIntervalSince1970)
                    ]
                }
                
                let updatedLog = try await strapiRepository.completeWorkoutLog(
                    workoutId: workoutId,
                    endTime: endTimeString,
                    distance: Float(workoutData.distance),
                    duration: Float(workoutData.duration),
                    calories: Float(workoutData.calories),
                    heartRateAverage: Int64(workoutData.heartRate),
                    route: routeData
                )
                
                print("Completed workout log: \(updatedLog.data.documentId)")
                
                // Log to HealthKit
                try await healthService.logWorkout(
                    type: workoutType.rawValue,
                    start: startTime ?? Date(),
                    end: endTime
                )
                
            } catch {
                print("Failed to complete workout log: \(error)")
            }
        }
    }
    
    private func startRealTimeSync() {
        // Start periodic sync to Strapi for live cheer integration
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncWorkoutData()
            }
        }
    }
    
    private func stopRealTimeSync() {
        // Final sync when workout stops
        syncWorkoutData()
    }
    
    private func syncWorkoutData() {
        Task {
            do {
                guard let workoutId = workoutId else { return }
                
                let routeData = routeCoordinates.map { location in
                    [
                        "latitude": Float(location.coordinate.latitude),
                        "longitude": Float(location.coordinate.longitude),
                        "timestamp": Float(location.timestamp.timeIntervalSince1970)
                    ]
                }
                
                _ = try await strapiRepository.updateWorkoutLog(
                    workoutId: workoutId,
                    distance: Float(workoutData.distance),
                    duration: Float(workoutData.duration),
                    calories: Float(workoutData.calories),
                    heartRateAverage: Int64(workoutData.heartRate),
                    route: routeData
                )
                
            } catch {
                print("Failed to sync workout data: \(error)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ActiveWorkoutManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            routeCoordinates.append(location)
            
            // Calculate distance
            if routeCoordinates.count > 1 {
                let previousLocation = routeCoordinates[routeCoordinates.count - 2]
                let distance = location.distance(from: previousLocation)
                workoutData.distance += distance
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
}

// MARK: - Data Models
struct ActiveWorkoutData {
    var duration: TimeInterval = 0
    var distance: Double = 0
    var calories: Double = 0
    var heartRate: Double = 0
    var laps: [LapData] = []
}

struct LapData {
    let number: Int
    let duration: TimeInterval
    let distance: Double
    let pace: Double
} 