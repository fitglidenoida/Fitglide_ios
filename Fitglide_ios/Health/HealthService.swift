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
            // Basic Activity
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            
            // Heart & Cardiovascular
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            
            // Sleep & Recovery
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .vo2Max)!,
            
            // Body Composition
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKQuantityType.quantityType(forIdentifier: .waistCircumference)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            
            // Nutrition & Hydration
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySugar)!,
            HKQuantityType.quantityType(forIdentifier: .dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryPotassium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryCalcium)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryIron)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminC)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryVitaminD)!,
            
            // Fitness & Performance
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKQuantityType.quantityType(forIdentifier: .appleStandTime)!,
            HKQuantityType.quantityType(forIdentifier: .pushCount)!,
            HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKQuantityType.quantityType(forIdentifier: .underwaterDepth)!,
            
            // Mindfulness & Mental Health
            HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
            HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure)!,
            HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!,
            
            // Reproductive Health
            HKCategoryType.categoryType(forIdentifier: .menstrualFlow)!,
            HKCategoryType.categoryType(forIdentifier: .intermenstrualBleeding)!,
            HKCategoryType.categoryType(forIdentifier: .sexualActivity)!,
            
            // Lab Results
            HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!,
            HKQuantityType.quantityType(forIdentifier: .bloodAlcoholContent)!,
            HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)!,
            HKQuantityType.quantityType(forIdentifier: .electrodermalActivity)!
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        ]
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
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
    
    func logHydration(amount: Double, date: Date) async throws {
        let hydrationType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let validatedAmount = validateHydrationData(amount)
        let quantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: validatedAmount * 1000.0) // Convert liters to ml
        
        let sample = HKQuantitySample(type: hydrationType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
        logger.info("Logged hydration: \(validatedAmount)L at \(date)")
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
                
                // Validate hydration data - filter out unrealistic values
                let validatedLiters = self.validateHydrationData(liters)
                
                print("HealthService: Fetched hydration for \(date): \(validatedLiters)L (raw: \(liters)L)")
                continuation.resume(returning: validatedLiters)
            }
            healthStore.execute(query)
        }
    }
    
    private func validateHydrationData(_ liters: Double) -> Double {
        // Filter out unrealistic hydration values
        // Normal daily water intake is typically 1.5-4 liters
        if liters > 10.0 {
            logger.warning("Unrealistic hydration value detected: \(liters)L, filtering out")
            return 0.0
        }
        
        if liters < 0 {
            logger.warning("Negative hydration value detected: \(liters)L, setting to 0")
            return 0.0
        }
        
        return liters
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

    // MARK: - Enhanced Data Fetching Methods
    
    // MARK: Body Composition
    func getBodyComposition(date: Date) async throws -> BodyCompositionData {
        async let weight = getWeight()
        async let bodyFat = getBodyFatPercentage(date: date)
        async let bmi = getBMI(date: date)
        async let height = getHeight()
        
        let (weightValue, bodyFatValue, bmiValue, heightValue) = try await (weight, bodyFat, bmi, height)
        
        return BodyCompositionData(
            weight: weightValue,
            bodyFatPercentage: bodyFatValue,
            bmi: bmiValue,
            height: heightValue
        )
    }
    
    func getBodyFatPercentage(date: Date) async throws -> Float? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        
        let sample = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKSampleQuery(sampleType: bodyFatType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: HKUnit.percent())
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
        return sample.map { Float($0 * 100) } // Convert to percentage
    }
    
    func getBMI(date: Date) async throws -> Float? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
        
        let sample = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKSampleQuery(sampleType: bmiType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: HKUnit.count())
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
        return sample.map { Float($0) }
    }
    
    func getHeight() async throws -> Float? {
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
        
        let sample = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: HKUnit.meter())
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
        return sample.map { Float($0) }
    }
    
    // MARK: Cardiovascular Health
    func getBloodPressure(date: Date) async throws -> BloodPressureData? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        
        async let systolicSamples = getQuantitySamples(for: systolicType, predicate: predicate)
        async let diastolicSamples = getQuantitySamples(for: diastolicType, predicate: predicate)
        
        let (systolicValues, diastolicValues) = try await (systolicSamples, diastolicSamples)
        
        guard !systolicValues.isEmpty && !diastolicValues.isEmpty else {
            return nil
        }
        
        let systolic = Float(systolicValues.reduce(0, +) / Double(systolicValues.count))
        let diastolic = Float(diastolicValues.reduce(0, +) / Double(diastolicValues.count))
        
        return BloodPressureData(systolic: systolic, diastolic: diastolic)
    }
    
    func getVO2Max(date: Date) async throws -> Float? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        
        let samples = try await getQuantitySamples(for: vo2MaxType, predicate: predicate)
        
        guard !samples.isEmpty else { return nil }
        
        let vo2Max = Float(samples.reduce(0, +) / Double(samples.count))
        print("HealthService: Fetched VO2 Max for \(date): \(vo2Max) ml/kg/min")
        return vo2Max
    }
    
    // MARK: Nutrition & Hydration
    func getWaterIntake(date: Date = Date()) async throws -> Float {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let waterIntake = result?.sumQuantity()?.doubleValue(for: HKUnit.literUnit(with: .milli)) ?? 0
                continuation.resume(returning: Float(waterIntake))
            }
            
            healthStore.execute(query)
        }
    }
    
    func getNutritionData(date: Date) async throws -> HealthNutritionData {
        async let calories = getCaloriesConsumed(date: date)
        async let protein = getNutritionValue(for: .dietaryProtein, date: date)
        async let carbs = getNutritionValue(for: .dietaryCarbohydrates, date: date)
        async let fat = getNutritionValue(for: .dietaryFatTotal, date: date)
        async let fiber = getNutritionValue(for: .dietaryFiber, date: date)
        async let sugar = getNutritionValue(for: .dietarySugar, date: date)
        async let sodium = getNutritionValue(for: .dietarySodium, date: date)
        
        let (caloriesValue, proteinValue, carbsValue, fatValue, fiberValue, sugarValue, sodiumValue) = try await (calories, protein, carbs, fat, fiber, sugar, sodium)
        
        return HealthNutritionData(
            caloriesConsumed: caloriesValue,
            protein: proteinValue,
            carbohydrates: carbsValue,
            fat: fatValue,
            fiber: fiberValue,
            sugar: sugarValue,
            sodium: sodiumValue
        )
    }
    
    func getCaloriesConsumed(date: Date) async throws -> Float {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        
        return Float(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let kcal = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            healthStore.execute(query)
        })
    }
    
    private func getNutritionValue(for identifier: HKQuantityTypeIdentifier, date: Date) async throws -> Float {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let nutritionType = HKQuantityType.quantityType(forIdentifier: identifier)!
        
        return Float(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: nutritionType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = result?.sumQuantity()?.doubleValue(for: HKUnit.gram()) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        })
    }
    
    // MARK: Fitness Metrics
    func getFitnessMetrics(date: Date) async throws -> FitnessMetricsData {
        async let exerciseTime = getAppleExerciseTime(date: date)
        async let standTime = getAppleStandTime(date: date)
        async let flightsClimbed = getFlightsClimbed(date: date)
        async let mindfulMinutes = getMindfulMinutes(date: date)
        
        let (exerciseTimeValue, standTimeValue, flightsClimbedValue, mindfulMinutesValue) = try await (exerciseTime, standTime, flightsClimbed, mindfulMinutes)
        
        return FitnessMetricsData(
            exerciseTime: exerciseTimeValue,
            standTime: standTimeValue,
            flightsClimbed: flightsClimbedValue,
            mindfulMinutes: mindfulMinutesValue
        )
    }
    
    func getAppleExerciseTime(date: Date) async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        
        return Int(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: exerciseTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        })
    }
    
    func getAppleStandTime(date: Date) async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let standTimeType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!
        
        return Int(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: standTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let minutes = result?.sumQuantity()?.doubleValue(for: HKUnit.minute()) ?? 0
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        })
    }
    
    func getFlightsClimbed(date: Date) async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
        
        return Int(try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: flightsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let flights = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: flights)
            }
            healthStore.execute(query)
        })
    }
    
    func getMindfulMinutes(date: Date) async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCategorySample] ?? [])
            }
            healthStore.execute(query)
        }
        
        let totalMinutes = samples.reduce(0) { total, sample in
            total + Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
        }
        
        return totalMinutes
    }
    
    // MARK: - Reproductive Health
    func getMenstrualFlow(date: Date = Date()) async throws -> [MenstrualFlowData] {
        let menstrualFlowType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow)!
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: menstrualFlowType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let flowData = samples?.compactMap { sample -> MenstrualFlowData? in
                    guard let categorySample = sample as? HKCategorySample else { return nil }
                    
                    let flowString: String
                    switch categorySample.value {
                    case HKCategoryValueVaginalBleeding.light.rawValue:
                        flowString = "Light"
                    case HKCategoryValueVaginalBleeding.medium.rawValue:
                        flowString = "Medium"
                    case HKCategoryValueVaginalBleeding.heavy.rawValue:
                        flowString = "Heavy"
                    default:
                        flowString = "Unknown"
                    }
                    
                    return MenstrualFlowData(flow: flowString, date: categorySample.startDate)
                } ?? []
                
                continuation.resume(returning: flowData)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getMenstrualFlowHistory(from startDate: Date, to endDate: Date) async throws -> [MenstrualFlowSample] {
        let menstrualFlowType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: menstrualFlowType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let flowSamples = samples?.compactMap { sample -> MenstrualFlowSample? in
                    guard let categorySample = sample as? HKCategorySample else { return nil }
                    
                    let flowValue: Int
                    switch categorySample.value {
                    case HKCategoryValueVaginalBleeding.light.rawValue:
                        flowValue = 1
                    case HKCategoryValueVaginalBleeding.medium.rawValue:
                        flowValue = 2
                    case HKCategoryValueVaginalBleeding.heavy.rawValue:
                        flowValue = 3
                    default:
                        flowValue = 0
                    }
                    
                    return MenstrualFlowSample(
                        startDate: categorySample.startDate,
                        endDate: categorySample.endDate,
                        value: flowValue
                    )
                } ?? []
                
                continuation.resume(returning: flowSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: Helper Methods
    private func getQuantitySamples(for quantityType: HKQuantityType, predicate: NSPredicate) async throws -> [Double] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Double], Error>) in
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) } ?? []
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Permission Status Check
    func checkPermissionStatus() async -> [String: Bool] {
        let readTypes: Set<HKObjectType> = [
            // Basic Activity
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            
            // Heart & Cardiovascular
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            
            // Sleep & Recovery
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            
            // Body Composition
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            
            // Nutrition & Hydration
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        var status: [String: Bool] = [:]
        
        for type in readTypes {
            let authStatus = healthStore.authorizationStatus(for: type)
            status[type.identifier] = authStatus == .sharingAuthorized
        }
        
        return status
    }
    
    func logPermissionStatus() async {
        let status = await checkPermissionStatus()
        logger.info("HealthKit Permission Status:")
        for (type, granted) in status {
            logger.info("\(type): \(granted ? "✅ Granted" : "❌ Denied")")
        }
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
    
    // MARK: - New Enhanced Data Structures
    struct BodyCompositionData {
        let weight: Float?
        let bodyFatPercentage: Float?
        let bmi: Float?
        let height: Float?
    }
    
    struct BloodPressureData {
        let systolic: Float
        let diastolic: Float
    }
    
    struct HealthNutritionData {
        let caloriesConsumed: Float
        let protein: Float
        let carbohydrates: Float
        let fat: Float
        let fiber: Float
        let sugar: Float
        let sodium: Float
    }
    
    struct FitnessMetricsData {
        let exerciseTime: Int
        let standTime: Int
        let flightsClimbed: Int
        let mindfulMinutes: Int
    }
    
    struct MenstrualFlowData {
        let flow: String
        let date: Date
    }
    
    struct MenstrualFlowSample {
        let startDate: Date
        let endDate: Date
        let value: Int
    }
    

}
