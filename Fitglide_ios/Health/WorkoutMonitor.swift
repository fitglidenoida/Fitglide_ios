//
//  WorkoutMonitor.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import HealthKit
import UserNotifications

@MainActor
class WorkoutMonitor: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var liveWorkoutType: String? = nil

    func startMonitoring() {
        let sampleType = HKObjectType.workoutType()

        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, _, error in
            guard let self = self else { return }
            guard error == nil else {
                print("Workout observer error: \(error!)")
                return
            }
            Task { @MainActor in
                await self.handleNewWorkout()
            }
        }

        healthStore.execute(query)
    }

    private func handleNewWorkout() async {
        let calendar = Calendar.current
        let now = Date()
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: oneHourAgo, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, _ in
            guard let self, let workout = samples?.first as? HKWorkout else { return }
            Task { @MainActor in
                self.sendWorkoutNotification(workout: workout)
            }
        }
        healthStore.execute(query)
    }

    private func sendWorkoutNotification(workout: HKWorkout) {
        let type = workout.workoutActivityType.readableName
        liveWorkoutType = type  // Triggers UI updates
        let content = UNMutableNotificationContent()
        content.title = "Share Your Workout?"
        content.body = "You just started a \(workout.workoutActivityType.readableName). Share it live?"
        content.sound = .default
        content.categoryIdentifier = "LIVE_WORKOUT"

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension HKWorkoutActivityType {
    var readableName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .yoga: return "Yoga"
        case .swimming: return "Swimming"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Workout"
        }
    }
}
