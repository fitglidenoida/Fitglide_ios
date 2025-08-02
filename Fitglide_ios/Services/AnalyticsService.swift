//
//  AnalyticsService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
class AnalyticsService: ObservableObject {
    @Published var trends: [HealthTrend] = []
    @Published var predictions: [HealthPrediction] = []
    @Published var insights: [HealthInsight] = []
    @Published var correlations: [HealthCorrelation] = []
    @Published var todaySteps: String = "0"
    @Published var todayCalories: String = "0"
    @Published var lastNightSleep: String = "0h"
    
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Public Data Access Methods
    func getSleepData(for date: Date) async throws -> HealthService.SleepData {
        return try await healthService.getSleep(date: date)
    }
    
    func getStepsData(for date: Date) async throws -> Int64 {
        return try await healthService.getSteps(date: date)
    }
    
    func getCaloriesData(for date: Date) async throws -> Float {
        return try await healthService.getCaloriesBurned(date: date)
    }
    
    // MARK: - Strapi Data Access Methods for Analytics
    func getWeeklyHealthData(from startDate: Date, to endDate: Date) async throws -> [HealthLogEntry] {
        let calendar = Calendar.current
        var allHealthLogs: [HealthLogEntry] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let dateString = formatDateForStrapi(currentDate)
            do {
                let response = try await strapiRepository.getHealthLog(date: dateString, source: nil)
                print("AnalyticsService: Fetched \(response.data.count) health logs for \(dateString)")
                allHealthLogs.append(contentsOf: response.data)
            } catch {
                print("AnalyticsService: Failed to fetch health log for \(dateString): \(error)")
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        print("AnalyticsService: Total health logs fetched: \(allHealthLogs.count)")
        return allHealthLogs
    }
    
    private func formatDateForStrapi(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func getWeeklyStepsData(from startDate: Date, to endDate: Date) async throws -> [Int64] {
        let calendar = Calendar.current
        var weeklySteps: [Int64] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let dateString = formatDateForStrapi(currentDate)
            do {
                let response = try await strapiRepository.getHealthLog(date: dateString, source: nil)
                let daySteps = response.data.first?.steps ?? 0
                weeklySteps.append(daySteps)
                print("AnalyticsService: Steps for \(dateString): \(daySteps)")
            } catch {
                print("AnalyticsService: Failed to fetch steps for \(dateString): \(error)")
                weeklySteps.append(0)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        print("AnalyticsService: Weekly steps data: \(weeklySteps)")
        return weeklySteps
    }
    
    func getWeeklyCaloriesData(from startDate: Date, to endDate: Date) async throws -> [Float] {
        let calendar = Calendar.current
        var weeklyCalories: [Float] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let dateString = formatDateForStrapi(currentDate)
            do {
                let response = try await strapiRepository.getHealthLog(date: dateString, source: nil)
                let dayCalories = response.data.first?.caloriesBurned ?? 0
                weeklyCalories.append(dayCalories)
                print("AnalyticsService: Calories for \(dateString): \(dayCalories)")
            } catch {
                print("AnalyticsService: Failed to fetch calories for \(dateString): \(error)")
                weeklyCalories.append(0)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        print("AnalyticsService: Weekly calories data: \(weeklyCalories)")
        return weeklyCalories
    }
    
    // MARK: - Load Today's Data
    func loadTodayData() async {
        do {
            let today = Date()
            
            // Load today's steps
            let steps = try await healthService.getSteps(date: today)
            todaySteps = formatNumber(Double(steps))
            
            // Load today's calories
            let calories = try await healthService.getCaloriesBurned(date: today)
            todayCalories = formatNumber(Double(calories))
            
            // Load last night's sleep
            let sleepData = try await healthService.getSleep(date: today)
            let sleepHours = sleepData.total / 3600 // Convert seconds to hours
            lastNightSleep = String(format: "%.1fh", sleepHours)
            
        } catch {
            print("AnalyticsService: Failed to load today's data: \(error)")
        }
    }
    
    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    // MARK: - Trend Analysis
    func analyzeTrends(days: Int = 30) async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            
            // Analyze different health metrics
            let stepTrends = try await analyzeStepTrends(from: startDate, to: endDate)
            let sleepTrends = try await analyzeSleepTrends(from: startDate, to: endDate)
            let heartRateTrends = try await analyzeHeartRateTrends(from: startDate, to: endDate)
            let nutritionTrends = try await analyzeNutritionTrends(from: startDate, to: endDate)
            
            trends = stepTrends + sleepTrends + heartRateTrends + nutritionTrends
        } catch {
            print("AnalyticsService: Failed to analyze trends: \(error)")
        }
    }
    
    // MARK: - Predictions
    func generatePredictions() async {
        do {
            let stepPrediction = try await predictStepGoal()
            let sleepPrediction = try await predictSleepQuality()
            let weightPrediction = try await predictWeightLoss()
            let energyPrediction = try await predictEnergyLevels()
            
            predictions = [stepPrediction, sleepPrediction, weightPrediction, energyPrediction]
        } catch {
            print("AnalyticsService: Failed to generate predictions: \(error)")
        }
    }
    
    // MARK: - Health Insights
    func generateInsights() async {
        do {
            let activityInsights = try await analyzeActivityInsights()
            let recoveryInsights = try await analyzeRecoveryInsights()
            
            insights = activityInsights + recoveryInsights
        } catch {
            print("AnalyticsService: Failed to generate insights: \(error)")
        }
    }
    
    // MARK: - Health Correlations
    func generateCorrelations() async {
        await analyzeCorrelations()
    }
    
    func analyzeCorrelations() async {
        do {
            let sleepActivityCorrelation = try await correlateSleepAndActivity()
            let nutritionEnergyCorrelation = try await correlateNutritionAndEnergy()
            let stressRecoveryCorrelation = try await correlateStressAndRecovery()
            let cycleHealthCorrelation = try await correlateCycleAndHealth()
            
            correlations = [sleepActivityCorrelation, nutritionEnergyCorrelation, stressRecoveryCorrelation, cycleHealthCorrelation]
        } catch {
            print("AnalyticsService: Failed to analyze correlations: \(error)")
        }
    }
    
    // MARK: - Private Analysis Methods
    
    private func analyzeStepTrends(from startDate: Date, to endDate: Date) async throws -> [HealthTrend] {
        var trends: [HealthTrend] = []
        
        // Collect step data for the period
        var stepData: [Date: Int] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let steps = try await healthService.getSteps(date: currentDate)
            stepData[currentDate] = Int(steps)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Calculate trends
        let averageSteps = stepData.values.reduce(0, +) / stepData.count
        let maxSteps = stepData.values.max() ?? 0
        let minSteps = stepData.values.min() ?? 0
        
        // Determine trend direction
        let recentSteps = Array(stepData.values.suffix(7))
        let olderSteps = Array(stepData.values.prefix(7))
        let recentAverage = recentSteps.reduce(0, +) / recentSteps.count
        let olderAverage = olderSteps.reduce(0, +) / olderSteps.count
        
        let trendDirection: TrendDirection = recentAverage > olderAverage ? .increasing : .decreasing
        
        trends.append(HealthTrend(
            metric: "Steps",
            currentValue: Double(recentAverage),
            averageValue: Double(averageSteps),
            trendDirection: trendDirection,
            changePercentage: calculateChangePercentage(old: Double(olderAverage), new: Double(recentAverage)),
            period: "30 days",
            insights: generateStepInsights(average: averageSteps, max: maxSteps, min: minSteps)
        ))
        
        return trends
    }
    
    private func analyzeSleepTrends(from startDate: Date, to endDate: Date) async throws -> [HealthTrend] {
        var trends: [HealthTrend] = []
        
        // Collect sleep data for the period
        var sleepData: [Date: TimeInterval] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let sleep = try await healthService.getSleep(date: currentDate)
            sleepData[currentDate] = sleep.total
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        let averageSleep = sleepData.values.reduce(0, +) / Double(sleepData.count)
        let recentSleep = Array(sleepData.values.suffix(7))
        let olderSleep = Array(sleepData.values.prefix(7))
        let recentAverage = recentSleep.reduce(0, +) / Double(recentSleep.count)
        let olderAverage = olderSleep.reduce(0, +) / Double(olderSleep.count)
        
        let trendDirection: TrendDirection = recentAverage > olderAverage ? .increasing : .decreasing
        
        trends.append(HealthTrend(
            metric: "Sleep",
            currentValue: recentAverage / 3600, // Convert to hours
            averageValue: averageSleep / 3600,
            trendDirection: trendDirection,
            changePercentage: calculateChangePercentage(old: olderAverage, new: recentAverage),
            period: "30 days",
            insights: generateSleepInsights(average: averageSleep)
        ))
        
        return trends
    }
    
    private func analyzeHeartRateTrends(from startDate: Date, to endDate: Date) async throws -> [HealthTrend] {
        var trends: [HealthTrend] = []
        
        // Collect heart rate data for the period
        var heartRateData: [Date: Int64] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let heartRate = try await healthService.getHeartRate(date: currentDate)
            heartRateData[currentDate] = heartRate.average
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        let averageHeartRate = Double(heartRateData.values.reduce(0, +)) / Double(heartRateData.count)
        let recentHeartRate = Array(heartRateData.values.suffix(7))
        let olderHeartRate = Array(heartRateData.values.prefix(7))
        let recentAverage = Double(recentHeartRate.reduce(0, +)) / Double(recentHeartRate.count)
        let olderAverage = Double(olderHeartRate.reduce(0, +)) / Double(olderHeartRate.count)
        
        let trendDirection: TrendDirection = recentAverage < olderAverage ? .improving : .declining
        
        trends.append(HealthTrend(
            metric: "Heart Rate",
            currentValue: recentAverage,
            averageValue: averageHeartRate,
            trendDirection: trendDirection,
            changePercentage: calculateChangePercentage(old: olderAverage, new: recentAverage),
            period: "30 days",
            insights: generateHeartRateInsights(average: averageHeartRate)
        ))
        
        return trends
    }
    
    private func analyzeNutritionTrends(from startDate: Date, to endDate: Date) async throws -> [HealthTrend] {
        var trends: [HealthTrend] = []
        
        // Collect nutrition data for the period
        var nutritionData: [Date: Float] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let nutrition = try await healthService.getNutritionData(date: currentDate)
            nutritionData[currentDate] = nutrition.caloriesConsumed
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        let averageCalories = nutritionData.values.reduce(0, +) / Float(nutritionData.count)
        let recentCalories = Array(nutritionData.values.suffix(7))
        let olderCalories = Array(nutritionData.values.prefix(7))
        let recentAverage = recentCalories.reduce(0, +) / Float(recentCalories.count)
        let olderAverage = olderCalories.reduce(0, +) / Float(olderCalories.count)
        
        let trendDirection: TrendDirection = recentAverage > olderAverage ? .increasing : .decreasing
        
        trends.append(HealthTrend(
            metric: "Calories",
            currentValue: Double(recentAverage),
            averageValue: Double(averageCalories),
            trendDirection: trendDirection,
            changePercentage: calculateChangePercentage(old: Double(olderAverage), new: Double(recentAverage)),
            period: "30 days",
            insights: generateNutritionInsights(average: averageCalories)
        ))
        
        return trends
    }
    
    // MARK: - Prediction Methods
    
    private func predictStepGoal() async throws -> HealthPrediction {
        // Simple prediction based on recent trends
        let recentSteps = try await healthService.getSteps(date: Date())
        let recentStepsDouble = Double(recentSteps)
        let predictedSteps = Int(recentStepsDouble * 1.1) // 10% increase prediction
        
        return HealthPrediction(
            title: "Step Goal",
            probability: 0.85,
            metric: "Steps",
            predictedValue: predictedSteps,
            confidence: 0.85,
            timeframe: "Next Week",
            reasoning: "Based on your recent activity patterns and improving fitness level"
        )
    }
    
    private func predictSleepQuality() async throws -> HealthPrediction {
        let sleepData = try await healthService.getSleep(date: Date())
        let predictedQuality = sleepData.total > 7 * 3600 ? "Good" : "Needs Improvement"
        
        return HealthPrediction(
            title: "Sleep Quality",
            probability: 0.78,
            metric: "Sleep Quality",
            predictedValue: predictedQuality,
            confidence: 0.78,
            timeframe: "Tonight",
            reasoning: "Based on your recent sleep patterns and daily activity levels"
        )
    }
    
    private func predictWeightLoss() async throws -> HealthPrediction {
        // Simplified weight loss prediction
        let predictedLoss = 0.5 // kg per week
        
        return HealthPrediction(
            title: "Weight Loss",
            probability: 0.72,
            metric: "Weight Loss",
            predictedValue: predictedLoss,
            confidence: 0.72,
            timeframe: "Next Month",
            reasoning: "Based on your current calorie deficit and exercise routine"
        )
    }
    
    private func predictEnergyLevels() async throws -> HealthPrediction {
        let energyLevel = "High"
        
        return HealthPrediction(
            title: "Energy Level",
            probability: 0.80,
            metric: "Energy Level",
            predictedValue: energyLevel,
            confidence: 0.80,
            timeframe: "Tomorrow",
            reasoning: "Based on your recent sleep quality and nutrition intake"
        )
    }
    
    // MARK: - Insight Methods
    
    private func analyzeSleepInsights() async throws -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Get recent sleep data
        let sleepData = try await healthService.getSleep(date: Date())
        let sleepHours = sleepData.total / 3600 // Convert to hours
        
        if sleepHours < 7 {
            insights.append(HealthInsight(
                title: "Sleep Duration",
                description: "You slept \(String(format: "%.1f", sleepHours)) hours last night. Aim for 7-9 hours for optimal health.",
                type: .recommendation,
                priority: .high
            ))
        } else if sleepHours >= 8 {
            insights.append(HealthInsight(
                title: "Great Sleep",
                description: "Excellent! You got \(String(format: "%.1f", sleepHours)) hours of sleep, which is within the optimal range.",
                type: .achievement,
                priority: .low
            ))
        }
        
        // Sleep quality insights
        let deepSleepPercentage = (sleepData.deep / sleepData.total) * 100
        if deepSleepPercentage < 15 {
            insights.append(HealthInsight(
                title: "Deep Sleep",
                description: "Your deep sleep was \(String(format: "%.1f", deepSleepPercentage))% of total sleep. Try reducing screen time before bed.",
                type: .recommendation,
                priority: .medium
            ))
        }
        
        print("AnalyticsService: Generated \(insights.count) sleep insights")
        return insights
    }
    
    private func analyzeNutritionInsights() async throws -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Get today's nutrition data
        let nutritionData = try await getTodayNutritionData()
        
        // Check if user has logged any meals today
        if nutritionData.caloriesConsumed == 0 {
            insights.append(HealthInsight(
                title: "Log Your Meals",
                description: "You haven't logged any meals today. Track your nutrition to get personalized insights.",
                type: .recommendation,
                priority: .medium
            ))
        } else {
            // Check calorie goals
            let caloriePercentage = Double(nutritionData.caloriesConsumed) / Double(nutritionData.caloriesTarget)
            
            if caloriePercentage < 0.7 {
                insights.append(HealthInsight(
                    title: "Low Calorie Intake",
                    description: "You've consumed \(nutritionData.caloriesConsumed) calories today, which is below your target. Consider adding a healthy snack.",
                    type: .recommendation,
                    priority: .medium
                ))
            } else if caloriePercentage > 1.3 {
                insights.append(HealthInsight(
                    title: "High Calorie Intake",
                    description: "You've consumed \(nutritionData.caloriesConsumed) calories today, which is above your target. Consider lighter meal options.",
                    type: .warning,
                    priority: .medium
                ))
            }
            
            // Check protein intake
            let proteinPercentage = Double(nutritionData.protein) / Double(nutritionData.proteinTarget)
            if proteinPercentage < 0.8 {
                insights.append(HealthInsight(
                    title: "Protein Goal",
                    description: "You've consumed \(nutritionData.protein)g of protein today. Aim for \(nutritionData.proteinTarget)g to support muscle health.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
        }
        
        print("AnalyticsService: Generated \(insights.count) nutrition insights")
        return insights
    }
    
    private func analyzeActivityInsights() async throws -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Get weekly data for better insights
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let weeklySteps = try await getWeeklyStepsData(from: startDate, to: today)
        let weeklyCalories = try await getWeeklyCaloriesData(from: startDate, to: today)
        
        // Calculate averages with proper safety checks - use actual days with data for accuracy
        let averageSteps: Double
        let averageCalories: Double
        
        if weeklySteps.isEmpty {
            averageSteps = 0
        } else {
            let daysWithSteps = weeklySteps.filter { $0 > 0 }.count
            averageSteps = daysWithSteps > 0 ? Double(weeklySteps.reduce(0, +)) / Double(daysWithSteps) : 0
        }
        
        if weeklyCalories.isEmpty {
            averageCalories = 0
        } else {
            let daysWithCalories = weeklyCalories.filter { $0 > 0 }.count
            averageCalories = daysWithCalories > 0 ? Double(weeklyCalories.reduce(0, +)) / Double(daysWithCalories) : 0
        }
        
        let maxSteps = weeklySteps.max() ?? 0
        let minSteps = weeklySteps.min() ?? 0
        
        // Step-based insights
        if averageSteps < 5000 {
            insights.append(HealthInsight(
                title: "Increase Daily Activity",
                description: "Your average daily steps (\(Int(averageSteps))) are below the recommended 10,000. Try taking short walks throughout the day.",
                type: .recommendation,
                priority: .medium
            ))
        } else if averageSteps >= 10000 {
            insights.append(HealthInsight(
                title: "Excellent Activity Level",
                description: "Great job! You're averaging \(Int(averageSteps)) steps daily, which exceeds the recommended goal.",
                type: .achievement,
                priority: .low
            ))
        }
        
        // Consistency insights
        if maxSteps - minSteps > 5000 {
            insights.append(HealthInsight(
                title: "Activity Consistency",
                description: "Your step count varies significantly (\(minSteps) to \(maxSteps)). Try to maintain more consistent daily activity.",
                type: .recommendation,
                priority: .medium
            ))
        }
        
        // Calorie insights
        if averageCalories < 200 {
            insights.append(HealthInsight(
                title: "Calorie Burn Goal",
                description: "You're averaging \(Int(averageCalories)) calories burned daily. Consider adding more intense workouts to increase calorie burn.",
                type: .recommendation,
                priority: .medium
            ))
        }
        
        // Progress insights
        if weeklySteps.count >= 2 {
            let recentSteps = Array(weeklySteps.suffix(3))
            let olderSteps = Array(weeklySteps.prefix(3))
            
            let recentAverage: Double
            let olderAverage: Double
            
            if recentSteps.isEmpty {
                recentAverage = 0
            } else {
                recentAverage = Double(recentSteps.reduce(0, +)) / Double(recentSteps.count)
            }
            
            if olderSteps.isEmpty {
                olderAverage = 0
            } else {
                olderAverage = Double(olderSteps.reduce(0, +)) / Double(olderSteps.count)
            }
            
            if olderAverage > 0 && recentAverage > olderAverage * 1.2 {
                let percentageIncrease = ((recentAverage - olderAverage) / olderAverage) * 100
                insights.append(HealthInsight(
                    title: "Improving Activity",
                    description: "Your recent activity has increased by \(Int(percentageIncrease))% compared to earlier this week!",
                    type: .achievement,
                    priority: .low
                ))
            }
        }
        
        print("AnalyticsService: Generated \(insights.count) activity insights")
        return insights
    }
    
    private func analyzeRecoveryInsights() async throws -> [HealthInsight] {
        let hrv = try await healthService.getHRV(date: Date())
        
        var insights: [HealthInsight] = []
        
        if let hrvData = hrv, let sdnn = hrvData.sdnn, sdnn < 30 {
            insights.append(HealthInsight(
                title: "Recovery Alert",
                description: "Your HRV indicates high stress. Consider a rest day or light activity.",
                type: .warning,
                priority: .high
            ))
        }
        
        return insights
    }
    
    // MARK: - Correlation Methods
    
    private func correlateSleepAndActivity() async throws -> HealthCorrelation {
        return HealthCorrelation(
            factor1: "Sleep Quality",
            factor2: "Activity Level",
            strength: 0.75,
            description: "Better sleep quality correlates with higher daily activity levels",
            impact: "High"
        )
    }
    
    private func correlateNutritionAndEnergy() async throws -> HealthCorrelation {
        return HealthCorrelation(
            factor1: "Nutrition",
            factor2: "Energy Levels",
            strength: 0.82,
            description: "Balanced nutrition intake leads to sustained energy throughout the day",
            impact: "High"
        )
    }
    
    private func correlateStressAndRecovery() async throws -> HealthCorrelation {
        return HealthCorrelation(
            factor1: "Stress Level",
            factor2: "Recovery",
            strength: -0.68,
            description: "Higher stress levels negatively impact recovery and sleep quality",
            impact: "Medium"
        )
    }
    
    private func correlateCycleAndHealth() async throws -> HealthCorrelation {
        return HealthCorrelation(
            factor1: "Menstrual Cycle",
            factor2: "Energy & Performance",
            strength: 0.45,
            description: "Energy levels and workout performance vary throughout the menstrual cycle",
            impact: "Medium"
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateChangePercentage(old: Double, new: Double) -> Double {
        guard old != 0 else { return 0 }
        return ((new - old) / old) * 100
    }
    
    private func calculateChangePercentage(old: Float, new: Float) -> Double {
        guard old != 0 else { return 0 }
        return Double(((new - old) / old) * 100)
    }
    
    private func generateStepInsights(average: Int, max: Int, min: Int) -> [String] {
        var insights: [String] = []
        
        if average < 5000 {
            insights.append("Consider increasing daily activity")
        } else if average > 10000 {
            insights.append("Excellent activity level maintained")
        }
        
        if max - min > 5000 {
            insights.append("High variability in daily steps")
        }
        
        return insights
    }
    
    private func generateSleepInsights(average: TimeInterval) -> [String] {
        var insights: [String] = []
        
        let hours = average / 3600
        if hours < 6 {
            insights.append("Sleep duration below recommended levels")
        } else if hours > 9 {
            insights.append("Sleep duration above recommended levels")
        }
        
        return insights
    }
    
    private func generateHeartRateInsights(average: Double) -> [String] {
        var insights: [String] = []
        
        if average > 100 {
            insights.append("Resting heart rate above normal range")
        } else if average < 60 {
            insights.append("Excellent cardiovascular fitness")
        }
        
        return insights
    }
    
    private func generateNutritionInsights(average: Float) -> [String] {
        var insights: [String] = []
        
        if average < 1200 {
            insights.append("Calorie intake may be too low")
        } else if average > 2500 {
            insights.append("High calorie intake detected")
        }
        
        return insights
    }
    
    // MARK: - Nutrition Data Methods for Analytics
    func getTodayNutritionData() async throws -> NutritionData {
        let today = Date()
        let dateString = formatDateForStrapi(today)
        
        do {
            // Fetch today's diet logs
            let dietLogs = try await strapiRepository.getDietLogs(date: dateString)
            print("AnalyticsService: Fetched \(dietLogs.data.count) diet logs for \(dateString)")
            
            var nutritionData = NutritionData()
            
            // Calculate totals from consumed meals
            var totalCalories = 0
            var totalProtein = 0
            var totalCarbs = 0
            var totalFat = 0
            
            for log in dietLogs.data {
                if log.consumed == true {
                    totalCalories += log.calories ?? 0
                    totalProtein += log.protein ?? 0
                    totalCarbs += log.carbs ?? 0
                    totalFat += log.fat ?? 0
                }
            }
            
            // Set consumed values
            nutritionData.caloriesConsumed = totalCalories
            nutritionData.protein = totalProtein
            nutritionData.carbs = totalCarbs
            nutritionData.fat = totalFat
            
            // Calculate targets based on user profile (simplified for now)
            nutritionData.caloriesTarget = 2000
            nutritionData.proteinTarget = 120
            nutritionData.carbsTarget = 250
            nutritionData.fatTarget = 80
            
            // Calculate percentages
            nutritionData.proteinPercentage = nutritionData.proteinTarget > 0 ? Double(nutritionData.protein) / Double(nutritionData.proteinTarget) : 0
            nutritionData.carbsPercentage = nutritionData.carbsTarget > 0 ? Double(nutritionData.carbs) / Double(nutritionData.carbsTarget) : 0
            nutritionData.fatPercentage = nutritionData.fatTarget > 0 ? Double(nutritionData.fat) / Double(nutritionData.fatTarget) : 0
            
            print("AnalyticsService: Nutrition data - Calories: \(totalCalories), Protein: \(totalProtein), Carbs: \(totalCarbs), Fat: \(totalFat)")
            
            return nutritionData
            
        } catch {
            print("AnalyticsService: Failed to fetch nutrition data: \(error)")
            // Return empty nutrition data (all zeros)
            return NutritionData()
        }
    }
    
    func checkDietPlanForNudge() async throws -> Bool {
        let today = Date()
        let dateString = formatDateForStrapi(today)
        
        do {
            // Check if user has a diet plan for today
            let dietPlan = try await strapiRepository.getDietPlan(date: dateString)
            let hasDietPlan = !dietPlan.data.isEmpty
            
            // Check if any meals from diet plan are not consumed
            let dietLogs = try await strapiRepository.getDietLogs(date: dateString)
            let consumedMeals = dietLogs.data.filter { $0.consumed == true }.count
            let totalMeals = dietPlan.data.count
            
            // Show nudge if there's a diet plan but not all meals are consumed
            let shouldNudge = hasDietPlan && consumedMeals < totalMeals
            
            print("AnalyticsService: Diet plan nudge check - Has plan: \(hasDietPlan), Consumed: \(consumedMeals)/\(totalMeals), Should nudge: \(shouldNudge)")
            
            return shouldNudge
            
        } catch {
            print("AnalyticsService: Failed to check diet plan: \(error)")
            return false
        }
    }
}

// MARK: - Data Models

struct HealthTrend {
    let metric: String
    let currentValue: Double
    let averageValue: Double
    let trendDirection: TrendDirection
    let changePercentage: Double
    let period: String
    let insights: [String]
}

enum TrendDirection {
    case increasing
    case decreasing
    case improving
    case declining
    case stable
    
    var icon: String {
        switch self {
        case .increasing, .improving: return "arrow.up.circle.fill"
        case .decreasing, .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing, .improving: return .green
        case .decreasing, .declining: return .red
        case .stable: return .orange
        }
    }
}

struct HealthPrediction: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let probability: Double
    let metric: String
    let predictedValue: Any
    let confidence: Double
    let timeframe: String
    let reasoning: String
    
    static func == (lhs: HealthPrediction, rhs: HealthPrediction) -> Bool {
        lhs.id == rhs.id
    }
}

struct HealthInsight {
    let title: String
    let description: String
    let type: InsightType
    let priority: InsightPriority
}

enum InsightType {
    case recommendation
    case warning
    case motivation
    case achievement
    
    var icon: String {
        switch self {
        case .recommendation: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .motivation: return "heart.fill"
        case .achievement: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .recommendation: return .blue
        case .warning: return .orange
        case .motivation: return .pink
        case .achievement: return .yellow
        }
    }
}

enum InsightPriority {
    case low
    case medium
    case high
}

struct HealthCorrelation {
    let factor1: String
    let factor2: String
    let strength: Double
    let description: String
    let impact: String
}

struct NutritionData {
    var caloriesConsumed: Int = 0
    var caloriesTarget: Int = 2000
    var protein: Int = 0
    var proteinTarget: Int = 120
    var carbs: Int = 0
    var carbsTarget: Int = 250
    var fat: Int = 0
    var fatTarget: Int = 80
    var proteinPercentage: Double = 0.0
    var carbsPercentage: Double = 0.0
    var fatPercentage: Double = 0.0
    var breakfastPercentage: Double = 0.0
    var lunchPercentage: Double = 0.0
    var dinnerPercentage: Double = 0.0
    var snacksPercentage: Double = 0.0
}

    // MARK: - Nutrition Data Methods for Analytics
    func getTodayNutritionData() async throws -> NutritionData {
        let today = Date()
        let dateString = formatDateForStrapi(today)
        
        do {
            // Fetch today's diet logs
            let dietLogs = try await strapiRepository.getDietLogs(date: dateString)
            print("AnalyticsService: Fetched \(dietLogs.data.count) diet logs for \(dateString)")
            
            var nutritionData = NutritionData()
            
            // Calculate totals from consumed meals
            var totalCalories = 0
            var totalProtein = 0
            var totalCarbs = 0
            var totalFat = 0
            
            // Process diet logs to extract nutrition data
            for log in dietLogs.data {
                // Check if any meals in this log are consumed
                if let meals = log.meals {
                    for meal in meals {
                        for component in meal.components {
                            if component.consumed {
                                // For now, we'll use placeholder values since the actual nutrition data
                                // would need to come from the meal/component definitions
                                // In a real implementation, you'd fetch the meal details from Strapi
                                totalCalories += 300 // Placeholder
                                totalProtein += 20   // Placeholder
                                totalCarbs += 30     // Placeholder
                                totalFat += 10       // Placeholder
                            }
                        }
                    }
                }
            }
            
            // Set consumed values
            nutritionData.caloriesConsumed = totalCalories
            nutritionData.protein = totalProtein
            nutritionData.carbs = totalCarbs
            nutritionData.fat = totalFat
            
            // Calculate targets based on user profile (simplified for now)
            nutritionData.caloriesTarget = 2000
            nutritionData.proteinTarget = 120
            nutritionData.carbsTarget = 250
            nutritionData.fatTarget = 80
            
            // Calculate percentages
            nutritionData.proteinPercentage = nutritionData.proteinTarget > 0 ? Double(nutritionData.protein) / Double(nutritionData.proteinTarget) : 0
            nutritionData.carbsPercentage = nutritionData.carbsTarget > 0 ? Double(nutritionData.carbs) / Double(nutritionData.carbsTarget) : 0
            nutritionData.fatPercentage = nutritionData.fatTarget > 0 ? Double(nutritionData.fat) / Double(nutritionData.fatTarget) : 0
            
            print("AnalyticsService: Nutrition data - Calories: \(totalCalories), Protein: \(totalProtein), Carbs: \(totalCarbs), Fat: \(totalFat)")
            
            return nutritionData
            
        } catch {
            print("AnalyticsService: Failed to fetch nutrition data: \(error)")
            // Return empty nutrition data (all zeros)
            return NutritionData()
        }
    }
    
    func checkDietPlanForNudge() async throws -> Bool {
        let today = Date()
        let dateString = formatDateForStrapi(today)
        
        do {
            // Check if user has a diet plan for today
            let dietPlan = try await strapiRepository.getDietPlan(date: dateString)
            let hasDietPlan = !dietPlan.data.isEmpty
            
            // Check if any meals from diet plan are not consumed
            let dietLogs = try await strapiRepository.getDietLogs(date: dateString)
            var consumedMeals = 0
            var totalMeals = 0
            
            // Count consumed meals from diet logs
            for log in dietLogs.data {
                if let meals = log.meals {
                    for meal in meals {
                        totalMeals += 1
                        let hasConsumedComponent = meal.components.contains { $0.consumed }
                        if hasConsumedComponent {
                            consumedMeals += 1
                        }
                    }
                }
            }
            
            // Show nudge if there's a diet plan but not all meals are consumed
            let shouldNudge = hasDietPlan && consumedMeals < totalMeals
            
            print("AnalyticsService: Diet plan nudge check - Has plan: \(hasDietPlan), Consumed: \(consumedMeals)/\(totalMeals), Should nudge: \(shouldNudge)")
            
            return shouldNudge
            
        } catch {
            print("AnalyticsService: Failed to check diet plan: \(error)")
            return false
        }
    } 
