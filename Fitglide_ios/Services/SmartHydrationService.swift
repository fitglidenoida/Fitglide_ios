import Foundation
import HealthKit
import Combine
import os.log

@MainActor
class SmartHydrationService: ObservableObject {
    @Published var smartGoal: SmartHydrationGoal?
    @Published var dailyProgress: HydrationProgress?
    @Published var insights: [HydrationInsight] = []
    @Published var userOverrideGoal: Double?
    @Published var overrideReason: String?
    
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "SmartHydration")
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Smart Goal Calculation
    func calculateSmartGoal() async {
        do {
            // Get user's health vitals
            guard let userId = authRepository.authState.userId else {
                logger.error("No user ID available for smart hydration calculation")
                return
            }
            
            let vitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            let vitals = vitalsResponse.data.first
            
            // Use fallback values if no vitals available
            let weight = Double(vitals?.WeightInKilograms ?? 70)
            let activityLevel = vitals?.activity_level
            
            // Base calculation: 30ml per kg of body weight
            let baseGoal = Double(weight) * 30 // ml per day
            
            // Activity level adjustments
            let activityAdjustment = calculateActivityAdjustment(activityLevel: activityLevel)
            
            // Workout adjustments
            let workoutAdjustment = await calculateWorkoutAdjustment()
            
            // Sleep quality adjustments
            let sleepAdjustment = await calculateSleepAdjustment()
            
            // Climate adjustments (placeholder for future weather API)
            let climateAdjustment = 0.0 // Will be implemented with weather API
            
            let totalGoal = baseGoal + activityAdjustment + workoutAdjustment + sleepAdjustment + climateAdjustment
            
            // Generate reasoning
            var reasoning: [String] = []
            reasoning.append("Base goal: \(Int(baseGoal))ml (30ml per kg)")
            
            if vitals == nil {
                reasoning.append("Using default weight (70kg) - update your profile for personalized goals")
            }
            
            if activityAdjustment > 0 {
                reasoning.append("Activity bonus: +\(Int(activityAdjustment))ml")
            }
            if workoutAdjustment > 0 {
                reasoning.append("Workout bonus: +\(Int(workoutAdjustment))ml")
            }
            if sleepAdjustment > 0 {
                reasoning.append("Sleep adjustment: +\(Int(sleepAdjustment))ml")
            }
            
            let smartGoal = SmartHydrationGoal(
                baseGoal: baseGoal,
                activityAdjustment: activityAdjustment,
                workoutAdjustment: workoutAdjustment,
                sleepAdjustment: sleepAdjustment,
                climateAdjustment: climateAdjustment,
                totalGoal: totalGoal,
                reasoning: reasoning,
                canOverride: true,
                overrideReason: nil
            )
            
            self.smartGoal = smartGoal
            
            // Calculate time-based progress
            await calculateDailyProgress()
            
            // Generate insights
            await generateInsights()
            
        } catch {
            logger.error("Failed to calculate smart hydration goal: \(error)")
        }
    }
    
    // MARK: - Activity Adjustments
    private func calculateActivityAdjustment(activityLevel: String?) -> Double {
        guard let level = activityLevel else { return 0 }
        
        switch level.lowercased() {
        case "sedentary":
            return 0
        case "lightly_active":
            return 250 // +250ml
        case "moderately_active":
            return 500 // +500ml
        case "very_active":
            return 750 // +750ml
        case "extremely_active":
            return 1000 // +1000ml
        default:
            return 0
        }
    }
    
    // MARK: - Workout Adjustments
    private func calculateWorkoutAdjustment() async -> Double {
        do {
            // Check if there's an active workout today
            let today = Date()
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: today)
            
            // Get workout data from HealthKit
            let workouts = try await healthService.getWorkout(date: startOfDay)
            let workoutAdjustment = (workouts.duration ?? 0) > 0 ? Double(workouts.duration ?? 0) * 250 / 3600 : 0 // 250ml per hour
            
            return workoutAdjustment
            
        } catch {
            logger.error("Failed to calculate workout adjustment: \(error)")
            return 0
        }
    }
    
    // MARK: - Sleep Adjustments
    private func calculateSleepAdjustment() async -> Double {
        do {
            let today = Date()
            let sleepData = try await healthService.getSleep(date: today)
            let sleepHours = sleepData.total / 3600 // Convert TimeInterval to hours
            
            // If sleep quality is poor (< 6 hours), add hydration
            if sleepHours < 6 {
                return 200 // +200ml for poor sleep
            }
            
            return 0
            
        } catch {
            logger.error("Failed to calculate sleep adjustment: \(error)")
            return 0
        }
    }
    
    // MARK: - Daily Progress Calculation
    private func calculateDailyProgress() async {
        guard let smartGoal = smartGoal else { 
            return 
        }
        
        do {
            let today = Date()
            let waterIntake = try await healthService.getHydration(date: today)
            
            let progress = HydrationProgress(
                currentIntake: Double(waterIntake),
                totalGoal: smartGoal.totalGoal,
                percentage: (Double(waterIntake) / smartGoal.totalGoal) * 100,
                timeBasedProgress: calculateTimeBasedProgress(currentIntake: Double(waterIntake), totalGoal: smartGoal.totalGoal)
            )
            
            self.dailyProgress = progress
            
        } catch {
            logger.error("Failed to calculate daily progress: \(error)")
        }
    }
    
    // MARK: - Time-based Progress
    private func calculateTimeBasedProgress(currentIntake: Double, totalGoal: Double) -> [String: Double] {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        let morningTarget = totalGoal * 0.25 // 25% by 10am
        let afternoonTarget = totalGoal * 0.65 // 65% by 4pm
        let eveningTarget = totalGoal * 0.90 // 90% by 8pm
        let nightTarget = totalGoal // 100% by end of day
        
        var progress: [String: Double] = [:]
        
        if currentHour >= 10 {
            progress["morning"] = min(currentIntake / morningTarget, 1.0)
        }
        if currentHour >= 16 {
            progress["afternoon"] = min(currentIntake / afternoonTarget, 1.0)
        }
        if currentHour >= 20 {
            progress["evening"] = min(currentIntake / eveningTarget, 1.0)
        }
        progress["night"] = min(currentIntake / nightTarget, 1.0)
        
        return progress
    }
    
    // MARK: - Insights Generation
    private func generateInsights() async {
        logger.debug("Generating hydration insights...")
        var newInsights: [HydrationInsight] = []
        
        guard let progress = dailyProgress, let smartGoal = smartGoal else { 
            logger.debug("No progress or smartGoal available for insights")
            return 
        }
        
        logger.debug("Generating insights with progress: \(progress.percentage)% and goal: \(smartGoal.totalGoal)ml")
        
        // Progress-based insights
        if progress.percentage < 50 {
            newInsights.append(HydrationInsight(
                type: .warning,
                title: "Hydration Alert",
                message: "You're behind on your hydration goal. Try to catch up!",
                icon: "exclamationmark.triangle.fill"
            ))
        } else if progress.percentage >= 100 {
            newInsights.append(HydrationInsight(
                type: .success,
                title: "Hydration Champion!",
                message: "You've reached your daily hydration goal. Great job!",
                icon: "checkmark.circle.fill"
            ))
        }
        
        // Time-based insights
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        
        if currentHour >= 10 && progress.percentage < 25 {
            newInsights.append(HydrationInsight(
                type: .reminder,
                title: "Morning Hydration",
                message: "Start your day with a glass of water to boost your metabolism.",
                icon: "sunrise.fill"
            ))
        }
        
        if currentHour >= 16 && progress.percentage < 65 {
            newInsights.append(HydrationInsight(
                type: .reminder,
                title: "Afternoon Boost",
                message: "Stay hydrated to maintain energy levels throughout the day.",
                icon: "sun.max.fill"
            ))
        }
        
        // Activity-based insights
        if smartGoal.workoutAdjustment > 0 {
            newInsights.append(HydrationInsight(
                type: .info,
                title: "Workout Hydration",
                message: "Your goal includes +\(Int(smartGoal.workoutAdjustment))ml for today's workout.",
                icon: "figure.run"
            ))
        }
        
        logger.debug("Generated \(newInsights.count) insights")
        self.insights = newInsights
    }
    
    // MARK: - User Override Functionality
    func setUserOverride(goal: Double, reason: String?) {
        userOverrideGoal = goal
        overrideReason = reason
        
        // Update smart goal with override
        if let currentSmartGoal = smartGoal {
            let updatedGoal = SmartHydrationGoal(
                baseGoal: currentSmartGoal.baseGoal,
                activityAdjustment: currentSmartGoal.activityAdjustment,
                workoutAdjustment: currentSmartGoal.workoutAdjustment,
                sleepAdjustment: currentSmartGoal.sleepAdjustment,
                climateAdjustment: currentSmartGoal.climateAdjustment,
                totalGoal: goal,
                reasoning: currentSmartGoal.reasoning,
                canOverride: false,
                overrideReason: reason
            )
            self.smartGoal = updatedGoal
        }
        
        // Recalculate progress with new goal
        Task {
            await calculateDailyProgress()
            await generateInsights()
        }
    }
    
    func clearUserOverride() {
        userOverrideGoal = nil
        overrideReason = nil
        
        // Recalculate original smart goal
        Task {
            await calculateSmartGoal()
        }
    }
    
    func getOverrideExplanation() -> String? {
        guard let overrideGoal = userOverrideGoal,
              let smartGoal = smartGoal else { return nil }
        
        let originalGoal = smartGoal.baseGoal + smartGoal.activityAdjustment + smartGoal.workoutAdjustment + smartGoal.sleepAdjustment + smartGoal.climateAdjustment
        
        if overrideGoal > originalGoal {
            return "You've increased your goal from \(Int(originalGoal))ml to \(Int(overrideGoal))ml. That's great for your active lifestyle!"
        } else if overrideGoal < originalGoal {
            return "You've set a more conservative goal of \(Int(overrideGoal))ml. Remember to stay hydrated!"
        } else {
            return "You've set a custom goal of \(Int(overrideGoal))ml."
        }
    }
    
    // MARK: - Smart Notifications
    func scheduleSmartNotifications() async {
        guard let smartGoal = smartGoal else { return }
        
        // Calculate optimal notification times based on goal
        let totalGoal = smartGoal.totalGoal
        let numNotifications = 5 // 5 notifications per day
        
        let waterPerNotification = totalGoal / Double(numNotifications)
        
        // Schedule notifications at optimal times
        let notificationTimes = [8, 10, 12, 15, 18] // 8am, 10am, 12pm, 3pm, 6pm
        
        for (index, hour) in notificationTimes.enumerated() {
            let targetAmount = waterPerNotification * Double(index + 1)
            
            // Schedule notification logic here
            logger.debug("Scheduling hydration notification for \(hour):00 with target \(Int(targetAmount))ml")
        }
    }
    
    // MARK: - Live Data Integration
    func startLiveMonitoring() {
        // Monitor activity changes every 15 minutes
        Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForActivityChanges()
            }
        }
    }
    
    private func checkForActivityChanges() async {
        do {
            // Check current step count
            let currentSteps = try await healthService.getSteps(date: Date())
            
            // Check for active workouts
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            let workouts = try await healthService.getWorkout(date: startOfDay)
            let activeWorkouts = (workouts.duration ?? 0) > 0 ? [workouts] : []
            
            // Check if we need to adjust goals
            var needsAdjustment = false
            var adjustmentReason = ""
            
            // High activity adjustment
            if currentSteps > 8000 && smartGoal?.workoutAdjustment == 0 {
                needsAdjustment = true
                adjustmentReason = "High step count detected"
            }
            
            // Active workout adjustment
            if !activeWorkouts.isEmpty && smartGoal?.workoutAdjustment == 0 {
                needsAdjustment = true
                adjustmentReason = "Active workout detected"
            }
            
            // Sleep quality adjustment
            let sleepData = try await healthService.getSleep(date: now)
            let sleepHours = sleepData.total / 3600 // Convert TimeInterval to hours
            if sleepHours < 6 && smartGoal?.sleepAdjustment == 0 {
                needsAdjustment = true
                adjustmentReason = "Poor sleep detected"
            }
            
            if needsAdjustment {
                logger.debug("Activity change detected: \(adjustmentReason). Recalculating smart goal.")
                await calculateSmartGoal()
                
                // Add insight about the adjustment
                let newInsight = HydrationInsight(
                    type: .info,
                    title: "Goal Updated",
                    message: "Your hydration goal has been adjusted based on \(adjustmentReason.lowercased()).",
                    icon: "arrow.up.circle.fill"
                )
                
                await MainActor.run {
                    if !self.insights.contains(where: { $0.title == "Goal Updated" }) {
                        self.insights.append(newInsight)
                    }
                }
            }
            
        } catch {
            logger.error("Failed to check for activity changes: \(error)")
        }
    }
    
    // MARK: - Live Cheer Integration
    func updateForLiveCheer(activityData: LiveActivityData) {
        Task {
            // Update based on live activity data
            var needsRecalculation = false
            
            // Check step count changes
            if activityData.steps > 8000 {
                needsRecalculation = true
            }
            
            // Check workout status
            if activityData.isWorkoutActive {
                needsRecalculation = true
            }
            
            // Check heart rate (high HR might indicate need for more hydration)
            if activityData.heartRate > 120 {
                needsRecalculation = true
            }
            
            if needsRecalculation {
                await calculateSmartGoal()
                
                // Add live insight
                let liveInsight = HydrationInsight(
                    type: .reminder,
                    title: "Live Update",
                    message: "Your activity level suggests you might need more hydration right now.",
                    icon: "bolt.fill"
                )
                
                await MainActor.run {
                    // Replace any existing live insights
                    self.insights.removeAll { $0.title == "Live Update" }
                    self.insights.append(liveInsight)
                }
            }
        }
    }
}

// MARK: - Data Models
struct SmartHydrationGoal {
    let baseGoal: Double
    let activityAdjustment: Double
    let workoutAdjustment: Double
    let sleepAdjustment: Double
    let climateAdjustment: Double
    let totalGoal: Double
    let reasoning: [String]
    let canOverride: Bool
    let overrideReason: String?
}

struct HydrationProgress {
    let currentIntake: Double
    let totalGoal: Double
    let percentage: Double
    let timeBasedProgress: [String: Double]
}

struct HydrationInsight {
    let type: HydrationInsightType
    let title: String
    let message: String
    let icon: String
}

enum HydrationInsightType {
    case success, warning, reminder, info
}

// MARK: - Live Activity Data Model
struct LiveActivityData {
    let steps: Int
    let isWorkoutActive: Bool
    let heartRate: Int
    let calories: Double
    let timestamp: Date
} 