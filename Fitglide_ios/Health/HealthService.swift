//
//  HealthService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 14/06/25.
//

import SwiftUI
import HealthKit
import os.log
import UserNotifications
import OSLog

@MainActor
class HealthService {
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "HealthService")
    
    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            fatalError("HealthKit not available on this device")
        }
        self.healthStore = HKHealthStore()
    }
    
    // MARK: - Permissions
    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: readTypes)
    }
    
    func logWaterIntake(amount: Double, date: Date) async throws {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let quantity = HKQuantity(unit: HKUnit.liter(), doubleValue: amount)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error = error {
                    self.logger.error("Failed to save water intake: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                self.logger.debug("Saved water intake: \(amount)L at \(date)")
                continuation.resume()
            }
        }
    }

    
    // MARK: - Data Fetching
    func getSteps(date: Date) async throws -> Int64 {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int64, Error>) in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let steps = Int64(sum.doubleValue(for: HKUnit.count()))
                print("HealthService: Fetched steps for \(date): \(steps)")
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    func getSleep(date: Date) async throws -> SleepData {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }

        if samples.isEmpty {
            let defaultStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: date)!
            let defaultEnd = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: date)!)!
            print("HealthService: No sleep data for \(date), returning default")
            return SleepData(total: 0, deep: 0, rem: 0, light: 0, awake: 0, start: defaultStart, end: defaultEnd)
        }

        var deep: TimeInterval = 0
        var rem: TimeInterval = 0
        var light: TimeInterval = 0
        var awake: TimeInterval = 0
        var earliestStart = end
        var latestEnd = start

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            earliestStart = min(earliestStart, sample.startDate)
            latestEnd = max(latestEnd, sample.endDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                light += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                light += duration
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                break
            default:
                print("HealthService: Unknown sleep sample value \(sample.value) for \(date)")
            }
        }

        let total = light + deep + rem

        // ✅ ISO 8601 UTC formatter with Z and fractional seconds
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        for sample in samples {
            let valueDescription: String
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                valueDescription = "inBed"
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                valueDescription = "asleepCore"
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                valueDescription = "asleepDeep"
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                valueDescription = "asleepREM"
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                valueDescription = "awake"
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                valueDescription = "asleepUnspecified"
            default:
                valueDescription = "unknown (value=\(sample.value))"
            }

            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            let startUTC = isoFormatter.string(from: sample.startDate)
            let endUTC = isoFormatter.string(from: sample.endDate)
            print("HealthService: Sleep sample for \(date): value=\(valueDescription), startUTC=\(startUTC), endUTC=\(endUTC), duration=\(duration)")
        }

        let startUTC = isoFormatter.string(from: earliestStart)
        let endUTC = isoFormatter.string(from: latestEnd)
        print("HealthService: Aggregated sleep for \(date): total=\(total), light=\(light), deep=\(deep), rem=\(rem), awake=\(awake), startUTC=\(startUTC), endUTC=\(endUTC)")

        return SleepData(
            total: total,
            deep: deep,
            rem: rem,
            light: light,
            awake: awake,
            start: earliestStart,
            end: latestEnd
        )
    }

    func getWorkout(date: Date) async throws -> WorkoutData {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let workoutType = HKObjectType.workoutType()
        
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKWorkout] ?? [])
            }
            healthStore.execute(query)
        }
        
        let steps = try await getSteps(date: date)
        let estimatedDistance = Double(steps) * 0.7 // 0.7m per step
        
        if workouts.isEmpty {
            print("HealthService: No workouts for \(date), returning default")
            return WorkoutData(start: date, end: date, distance: 0, duration: 0, calories: 0, heartRateAvg: 0, type: "")
        }
        
        let mostRecent = workouts.max(by: { $0.startDate < $1.startDate })!
        let duration = mostRecent.duration
        let distance = mostRecent.totalDistance?.doubleValue(for: HKUnit.meter()) ?? estimatedDistance
        
        // Fetch calories using HKStatisticsQuery
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let caloriePredicate = HKQuery.predicateForSamples(withStart: mostRecent.startDate, end: mostRecent.endDate, options: .strictStartDate)
        
        let calories = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: caloriePredicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let kcal = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? (duration / 60 * 10) // 10 kcal/minute fallback
                continuation.resume(returning: kcal)
            }
            healthStore.execute(query)
        }
        
        let heartRatePredicate = HKQuery.predicateForSamples(withStart: mostRecent.startDate, end: mostRecent.endDate, options: .strictStartDate)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let heartRates = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Double], Error>) in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: heartRatePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) } ?? []
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }
        
        let heartRateAvg = heartRates.isEmpty ? nil : Int64(heartRates.reduce(0, +) / Double(heartRates.count))
        
        let type: String
        switch mostRecent.workoutActivityType {
        case .running: type = "Running"
        case .cycling: type = "Cycling"
        default: type = "Cardio"
        }
        
        let workoutData = WorkoutData(
            start: mostRecent.startDate,
            end: mostRecent.endDate,
            distance: Float(distance),
            duration: Float(duration),
            calories: Float(calories),
            heartRateAvg: heartRateAvg,
            type: type
        )
        print("HealthService: Fetched workout for \(date): \(workoutData)")
        return workoutData
    }
    
    func getHeartRate(date: Date) async throws -> HeartRateData {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let heartRates = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Double], Error>) in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) } ?? []
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }
        
        var average: Int64 = 0
        if !heartRates.isEmpty {
            average = Int64(heartRates.reduce(0, +) / Double(heartRates.count))
        } else {
            // Fallback to resting heart rate if no regular heart rate data
            let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
            let restingHeartRates = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Double], Error>) in
                let query = HKSampleQuery(sampleType: restingHeartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) } ?? []
                    continuation.resume(returning: values)
                }
                healthStore.execute(query)
            }
            
            if !restingHeartRates.isEmpty {
                average = Int64(restingHeartRates.reduce(0, +) / Double(restingHeartRates.count))
            }
        }
        
        if average == 0 {
            print("HealthService: No heart rate data for \(date)")
        } else {
            print("HealthService: Fetched heart rate for \(date): average=\(average)")
        }
        return HeartRateData(average: average)
    }
    
    func getHydration(date: Date) async throws -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let liters = result?.sumQuantity()?.doubleValue(for: HKUnit.liter()) ?? 0
                print("HealthService: Fetched hydration for \(date): \(liters)L")
                continuation.resume(returning: liters)
            }
            healthStore.execute(query)
        }
    }
    
    func getWeight() async throws -> Float? {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        
        let sample = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                print("HealthService: Fetched weight: \(value ?? 0)kg")
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
        return sample.map { Float($0) }
    }
    
    func getHRV(date: Date) async throws -> HRVData? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Double], Error>) in
            let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) } ?? []
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }
        
        guard !samples.isEmpty else {
            print("HealthService: No HRV data for \(date)")
            return nil
        }
        
        let sdnn = Float(samples.reduce(0, +) / Double(samples.count))
        print("HealthService: Fetched HRV for \(date): SDNN=\(sdnn)ms")
        return HRVData(sdnn: sdnn)
    }
    
    func getCaloriesBurned(date: Date) async throws -> Float {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        return Float(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let kcal = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                print("HealthService: Fetched calories burned for \(date): \(kcal)kcal")
                continuation.resume(returning: kcal)
            }
            healthStore.execute(query)
        })
    }
    
    func getDistanceWalked(date: Date) async throws -> Float {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        return Float(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let meters = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                print("HealthService: Fetched distance walked for \(date): \(meters)m")
                continuation.resume(returning: meters)
            }
            healthStore.execute(query)
        })
    }
    
    func getBloodOxygen(date: Date) async throws -> Float? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Double], Error>) in
            let query = HKSampleQuery(sampleType: spo2Type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let values = (samples as? [HKQuantitySample])?.map {
                    $0.quantity.doubleValue(for: HKUnit.percent()) * 100
                } ?? []
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }

        let spo2 = samples.isEmpty ? nil : samples.reduce(0, +) / Double(samples.count)
        print("HealthService: Fetched blood oxygen for \(date): \(spo2 ?? 0)%")
        return spo2.map { Float($0) }
    }

    // MARK: - Workout Logging
    func logWorkout(type: String, start: Date, end: Date) async throws {
        let configuration = HKWorkoutConfiguration()
        switch type.lowercased() {
        case "running": configuration.activityType = .running
        case "cycling": configuration.activityType = .cycling
        default: configuration.activityType = .other
        }

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: start) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: end) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        _ = try await builder.finishWorkout()
        print("HealthService: Logged workout: \(type) from \(start) to \(end)")
    }

    // MARK: - Data Structures
    struct SleepData {
        let total: TimeInterval
        let deep: TimeInterval
        let rem: TimeInterval
        let light: TimeInterval
        let awake: TimeInterval
        let start: Date
        let end: Date
        
        init(total: TimeInterval, deep: TimeInterval, rem: TimeInterval, light: TimeInterval, awake: TimeInterval, start: Date, end: Date) {
            self.total = total
            self.deep = deep
            self.rem = rem
            self.light = light
            self.awake = awake
            self.start = start
            self.end = end
        }
    }
    
    struct WorkoutData {
        let start: Date?
        let end: Date?
        let distance: Float?
        let duration: Float?
        let calories: Float?
        let heartRateAvg: Int64?
        let type: String?
        
        init(start: Date?, end: Date?, distance: Float?, duration: Float?, calories: Float?, heartRateAvg: Int64?, type: String?) {
            self.start = start
            self.end = end
            self.distance = distance
            self.duration = duration
            self.calories = calories
            self.heartRateAvg = heartRateAvg
            self.type = type
        }
    }

    struct HeartRateData {
        let average: Int64
    }
    
    struct HRVData {
        let sdnn: Float?
    }
    
    struct HealthVitalsRequest: Codable {
        let dateTime: String
        let weight: Float
        let hrvSdnn: Float?
        let spo2: Float
        let usersPermissionsUser: UserId
        
        enum CodingKeys: String, CodingKey {
            case dateTime
            case weight
            case hrvSdnn = "hrv_sdnn"
            case spo2
            case usersPermissionsUser = "users_permissions_user"
        }
    }

    struct UserId: Codable {
        let id: String
    }
}
