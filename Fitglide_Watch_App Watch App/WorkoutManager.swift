//
//  WorkoutManager.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 27/07/25.
//

import Foundation
import HealthKit
import WatchKit
import Combine

class WorkoutManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    @Published var isWorkoutActive = false
    @Published var currentWorkoutType = "None"
    @Published var workoutDuration: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    @Published var distance: Double = 0
    
    private var timer: Timer?
    private var startDate: Date?
    
    override init() {
        super.init()
    }
    
    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit authorization granted")
                } else {
                    print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
    
    func startWorkout(type: HKWorkoutActivityType) {
        guard !isWorkoutActive else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        configuration.locationType = .outdoor
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            
            session.delegate = self
            builder.delegate = self
            
            workoutSession = session
            workoutBuilder = builder
            
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.isWorkoutActive = true
                        self.currentWorkoutType = self.workoutTypeName(for: type)
                        self.startDate = Date()
                        self.startTimer()
                        self.notifyLiveCheerStart()
                    } else {
                        print("❌ Failed to start workout: \(error?.localizedDescription ?? "unknown error")")
                    }
                }
            }
        } catch {
            print("❌ Failed to create workout session: \(error.localizedDescription)")
        }
    }
    
    func endWorkout() {
        guard isWorkoutActive else { return }
        
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.workoutBuilder?.finishWorkout { workout, error in
                        DispatchQueue.main.async {
                            self.resetWorkout()
                            self.notifyLiveCheerEnd()
                        }
                    }
                } else {
                    print("❌ Failed to end workout: \(error?.localizedDescription ?? "unknown error")")
                    self.resetWorkout()
                }
            }
        }
    }
    
    private func resetWorkout() {
        isWorkoutActive = false
        currentWorkoutType = "None"
        workoutDuration = 0
        heartRate = 0
        calories = 0
        distance = 0
        startDate = nil
        stopTimer()
        
        workoutSession = nil
        workoutBuilder = nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startDate = self.startDate {
                self.workoutDuration = Date().timeIntervalSince(startDate)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func workoutTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Workout"
        }
    }
    
    private func notifyLiveCheerStart() {
        // Notify the LiveCheerManager that a workout has started
        NotificationCenter.default.post(name: .workoutStarted, object: nil, userInfo: [
            "workoutType": currentWorkoutType,
            "startTime": startDate ?? Date()
        ])
    }
    
    private func notifyLiveCheerEnd() {
        // Notify the LiveCheerManager that a workout has ended
        NotificationCenter.default.post(name: .workoutEnded, object: nil, userInfo: [
            "duration": workoutDuration,
            "calories": calories,
            "distance": distance
        ])
    }
    
    var formattedDuration: String {
        let hours = Int(workoutDuration) / 3600
        let minutes = Int(workoutDuration) / 60 % 60
        let seconds = Int(workoutDuration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                print("🏃‍♂️ Workout session started/resumed")
            case .ended:
                print("🏁 Workout session ended")
            case .paused:
                print("⏸️ Workout session paused")
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Workout session failed: \(error.localizedDescription)")
            self.resetWorkout()
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    if let heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
                        self.heartRate = heartRate
                    }
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    if let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                        self.calories = calories
                    }
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    if let distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) {
                        self.distance = distance
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let workoutStarted = Notification.Name("workoutStarted")
    static let workoutEnded = Notification.Name("workoutEnded")
} 