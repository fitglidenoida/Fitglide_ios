import Foundation
import HealthKit

class HealthService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("✅ HealthKit authorization granted for HealthService")
            } else {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func fetchTodayHealthData() async -> WatchHealthData {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        var healthData = WatchHealthData()
        
        // Fetch steps
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                if let result = result, let sum = result.sumQuantity() {
                    healthData.steps = Int(sum.doubleValue(for: HKUnit.count()))
                }
            }
            healthStore.execute(stepQuery)
        }
        
        // Fetch heart rate (most recent)
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let heartRateQuery = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                if let result = result, let average = result.averageQuantity() {
                    healthData.heartRate = Int(average.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                }
            }
            healthStore.execute(heartRateQuery)
        }
        
        // Fetch calories
        if let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let calorieQuery = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                if let result = result, let sum = result.sumQuantity() {
                    healthData.calories = Int(sum.doubleValue(for: .kilocalorie()))
                }
            }
            healthStore.execute(calorieQuery)
        }
        
        // Fetch distance
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let distanceQuery = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                if let result = result, let sum = result.sumQuantity() {
                    healthData.distance = sum.doubleValue(for: .meter()) / 1000.0 // Convert to kilometers
                }
            }
            healthStore.execute(distanceQuery)
        }
        
        // Wait a bit for queries to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return healthData
    }
}

// MARK: - Health Data Model
struct WatchHealthData {
    var steps: Int = 0
    var heartRate: Int = 0
    var calories: Int = 0
    var distance: Double = 0.0
    var isWorkoutActive: Bool = false
} 
