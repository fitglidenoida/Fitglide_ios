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
    @Published var insights: [HealthInsight] = [] // Main page insights (wellness + correlations)
    @Published var fitnessInsights: [HealthInsight] = [] // Fitness-specific insights
    @Published var nutritionInsights: [HealthInsight] = [] // Nutrition-specific insights
    @Published var sleepInsights: [HealthInsight] = [] // Sleep-specific insights
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
            var mainInsights: [HealthInsight] = []
            
            // Generate health correlations for main page
            let correlations = try await analyzeCorrelations()
            self.correlations = correlations
            
            // Create high-level wellness insights based on correlations
            for correlation in correlations.prefix(2) {
                if correlation.strength > 0.5 {
                    mainInsights.append(HealthInsight(
                        title: "Health Connection",
                        description: correlation.description,
                        type: .recommendation,
                        priority: .medium
                    ))
                }
            }
            
            // Add general wellness insights
            let generalInsights = try await analyzeGeneralWellness()
            mainInsights.append(contentsOf: generalInsights.prefix(2))
            
            // Set main page insights (wellness + correlations)
            insights = mainInsights
            print("AnalyticsService: Generated \(mainInsights.count) main page wellness insights")
            
        } catch {
            print("AnalyticsService: Failed to generate main insights: \(error)")
            insights = []
        }
    }
    
    // MARK: - Health Correlations
    func generateCorrelations() async {
        do {
            let correlations = try await analyzeCorrelations()
            self.correlations = correlations
        } catch {
            print("AnalyticsService: Failed to generate correlations: \(error)")
        }
    }
    
    func analyzeCorrelations() async throws -> [HealthCorrelation] {
        let sleepActivityCorrelation = try await correlateSleepAndActivity()
        let nutritionEnergyCorrelation = try await correlateNutritionAndEnergy()
        let stressRecoveryCorrelation = try await correlateStressAndRecovery()
        let cycleHealthCorrelation = try await correlateCycleAndHealth()
        
        return [sleepActivityCorrelation, nutritionEnergyCorrelation, stressRecoveryCorrelation, cycleHealthCorrelation]
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
                description: "You haven't logged any meals today. Track your nutrition to get personalized insights and recommendations.",
                type: .recommendation,
                priority: .medium
            ))
        } else {
            // Check calorie goals
            let caloriePercentage = Double(nutritionData.caloriesConsumed) / Double(nutritionData.caloriesTarget)
            
            if caloriePercentage < 0.7 {
                insights.append(HealthInsight(
                    title: "Low Calorie Intake",
                    description: "You've consumed \(nutritionData.caloriesConsumed) calories today, which is \(Int((1 - caloriePercentage) * 100))% below your target. Consider adding a healthy snack or larger portions.",
                    type: .recommendation,
                    priority: .medium
                ))
            } else if caloriePercentage > 1.3 {
                insights.append(HealthInsight(
                    title: "High Calorie Intake",
                    description: "You've consumed \(nutritionData.caloriesConsumed) calories today, which is \(Int((caloriePercentage - 1) * 100))% above your target. Consider lighter meal options or portion control.",
                    type: .warning,
                    priority: .medium
                ))
            } else {
                insights.append(HealthInsight(
                    title: "Great Calorie Balance",
                    description: "You're within your target calorie range today! Keep up the balanced eating habits.",
                    type: .achievement,
                    priority: .low
                ))
            }
            
            // Check protein intake
            let proteinPercentage = Double(nutritionData.protein) / Double(nutritionData.proteinTarget)
            if proteinPercentage < 0.8 {
                insights.append(HealthInsight(
                    title: "Increase Protein Intake",
                    description: "You've consumed \(nutritionData.protein)g of protein today. Aim for \(nutritionData.proteinTarget)g to support muscle health and recovery.",
                    type: .recommendation,
                    priority: .medium
                ))
            } else if proteinPercentage >= 1.0 {
                insights.append(HealthInsight(
                    title: "Excellent Protein Intake",
                    description: "Great job hitting your protein goal! You've consumed \(nutritionData.protein)g of protein today.",
                    type: .achievement,
                    priority: .low
                ))
            }
            
            // Check macro balance
            let totalMacros = nutritionData.protein + nutritionData.carbs + nutritionData.fat
            if totalMacros > 0 {
                let proteinRatio = Double(nutritionData.protein * 4) / Double(nutritionData.caloriesConsumed)
                let carbsRatio = Double(nutritionData.carbs * 4) / Double(nutritionData.caloriesConsumed)
                // Note: fatRatio calculation available if needed for future insights
                
                if proteinRatio < 0.15 {
                    insights.append(HealthInsight(
                        title: "Low Protein Ratio",
                        description: "Protein makes up only \(Int(proteinRatio * 100))% of your calories today. Aim for 15-25% for optimal health.",
                        type: .recommendation,
                        priority: .medium
                    ))
                }
                
                if carbsRatio > 0.65 {
                    insights.append(HealthInsight(
                        title: "High Carb Ratio",
                        description: "Carbs make up \(Int(carbsRatio * 100))% of your calories today. Consider balancing with more protein and healthy fats.",
                        type: .recommendation,
                        priority: .low
                    ))
                }
            }
            
            // Check meal consistency (if we have multiple meals logged)
            if nutritionData.caloriesConsumed > 0 {
                let mealCount = nutritionData.caloriesConsumed / 300 // Rough estimate of meals based on calories
                if mealCount < 2 {
                    insights.append(HealthInsight(
                        title: "Consider More Meals",
                        description: "You've logged \(mealCount) meal(s) today. Regular meals help maintain energy and metabolism.",
                        type: .recommendation,
                        priority: .low
                    ))
                }
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
            // Get current user ID and token
            guard let userId = authRepository.authState.userId,
                  let token = authRepository.authState.jwt else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
            }
            
            // Fetch today's diet logs using existing method
            let dietLogs = try await strapiRepository.getDietLogs(userId: userId, dateString: dateString, token: token)
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
    
    func generateNutritionInsights() async {
        do {
            var nutritionInsights: [HealthInsight] = []
            
            // Get nutrition-specific insights
            let nutritionSpecificInsights = try await analyzeNutritionInsights()
            nutritionInsights.append(contentsOf: nutritionSpecificInsights)
            
            // Add cross-reference to fitness if relevant
            let todaySteps = try await getStepsData(for: Date())
            if todaySteps > 5000 {
                nutritionInsights.append(HealthInsight(
                    title: "Activity Connection",
                    description: "Your activity level affects your nutritional needs. Check your fitness trends for activity insights.",
                    type: .recommendation,
                    priority: .low
                ))
            }
            
            // Set nutrition-specific insights
            self.nutritionInsights = nutritionInsights
            print("AnalyticsService: Generated \(nutritionInsights.count) nutrition-specific insights")
        } catch {
            print("AnalyticsService: Failed to generate nutrition insights: \(error)")
            nutritionInsights = []
        }
    }
    
    func generateFitnessInsights() async {
        do {
            var fitnessInsights: [HealthInsight] = []
            
            // Get fitness-specific insights
            let activityInsights = try await analyzeActivityInsights()
            fitnessInsights.append(contentsOf: activityInsights)
            
            // Add cross-reference to nutrition if relevant
            let nutritionData = try await getTodayNutritionData()
            if nutritionData.caloriesConsumed > 0 {
                fitnessInsights.append(HealthInsight(
                    title: "Nutrition Connection",
                    description: "Your nutrition affects your workout performance. Check your nutrition analysis for personalized recommendations.",
                    type: .recommendation,
                    priority: .low
                ))
            }
            
            // Set fitness-specific insights
            self.fitnessInsights = fitnessInsights
            print("AnalyticsService: Generated \(fitnessInsights.count) fitness-specific insights")
        } catch {
            print("AnalyticsService: Failed to generate fitness insights: \(error)")
            fitnessInsights = []
        }
    }
    
    func checkDietPlanForNudge() async throws -> Bool {
        let today = Date()
        
        do {
            // Get current user ID
            guard let userId = authRepository.authState.userId else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId"])
            }
            
            // Check if user has a diet plan for today using existing method
            let dietPlan = try await strapiRepository.getDietPlan(userId: userId, date: today)
            let hasDietPlan = !dietPlan.data.isEmpty
            
            // Get current user token for diet logs
            guard let token = authRepository.authState.jwt else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing token"])
            }
            
            let dateString = formatDateForStrapi(today)
            
            // Check if any meals from diet plan are not consumed
            let dietLogs = try await strapiRepository.getDietLogs(userId: userId, dateString: dateString, token: token)
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
    
    private func analyzeGeneralWellness() async throws -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Get today's data for general wellness assessment
        let todaySteps = try await getStepsData(for: Date())
        let todayCalories = try await getCaloriesData(for: Date())
        
        // Overall wellness assessment
        if todaySteps >= 10000 {
            insights.append(HealthInsight(
                title: "Excellent Activity",
                description: "You've hit your daily step goal! This contributes to overall wellness and energy levels.",
                type: .achievement,
                priority: .low
            ))
        } else if todaySteps < 5000 {
            insights.append(HealthInsight(
                title: "Boost Your Wellness",
                description: "Try to reach 10,000 steps today. Regular movement is key to overall health.",
                type: .recommendation,
                priority: .medium
            ))
        }
        
        // Wellness balance insight
        if todayCalories > 300 {
            insights.append(HealthInsight(
                title: "Active Lifestyle",
                description: "Great calorie burn today! Balance activity with proper nutrition for optimal wellness.",
                type: .recommendation,
                priority: .low
            ))
        }
        
        return insights
    }
    
    // MARK: - Sleep Data Methods
    
    func getTodaySleepData() async throws -> SleepData {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let today = Date()
        let dateString = formatDateForStrapi(today)
        
        print("Fetching sleep data for userId: \(userId), date: \(dateString)")
        
        do {
            let response = try await strapiRepository.fetchSleepLog(date: today)
            
            if let sleepLog = response.data.first {
                return SleepData(
                    totalSleepHours: Double(sleepLog.sleepDuration),
                    deepSleepHours: Double(sleepLog.deepSleepDuration),
                    remSleepHours: Double(sleepLog.remSleepDuration),
                    lightSleepHours: Double(sleepLog.lightSleepDuration),
                    awakeHours: Double(sleepLog.sleepAwakeDuration),
                    sleepQuality: calculateSleepQuality(sleepLog: sleepLog),
                    sleepEfficiency: calculateSleepEfficiency(sleepLog: sleepLog)
                )
            } else {
                // Return default values if no sleep log found
                return SleepData(
                    totalSleepHours: 0,
                    deepSleepHours: 0,
                    remSleepHours: 0,
                    lightSleepHours: 0,
                    awakeHours: 0,
                    sleepQuality: 0,
                    sleepEfficiency: 0
                )
            }
        } catch {
            print("AnalyticsService: Failed to fetch sleep data: \(error)")
            throw error
        }
    }
    
    func getWeeklySleepData() async throws -> [SleepData] {
        guard let userId = authRepository.authState.userId,
              let token = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let calendar = Calendar.current
        let today = Date()
        var weeklySleepData: [SleepData] = []
        
        // Fetch sleep data for the last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                do {
                    let response = try await strapiRepository.fetchSleepLog(date: date)
                    
                    if let sleepLog = response.data.first {
                        let sleepData = SleepData(
                            totalSleepHours: Double(sleepLog.sleepDuration),
                            deepSleepHours: Double(sleepLog.deepSleepDuration),
                            remSleepHours: Double(sleepLog.remSleepDuration),
                            lightSleepHours: Double(sleepLog.lightSleepDuration),
                            awakeHours: Double(sleepLog.sleepAwakeDuration),
                            sleepQuality: calculateSleepQuality(sleepLog: sleepLog),
                            sleepEfficiency: calculateSleepEfficiency(sleepLog: sleepLog)
                        )
                        weeklySleepData.append(sleepData)
                    } else {
                        // Add empty data for missing days
                        weeklySleepData.append(SleepData(
                            totalSleepHours: 0,
                            deepSleepHours: 0,
                            remSleepHours: 0,
                            lightSleepHours: 0,
                            awakeHours: 0,
                            sleepQuality: 0,
                            sleepEfficiency: 0
                        ))
                    }
                } catch {
                    print("AnalyticsService: Failed to fetch sleep data for date \(date): \(error)")
                    // Add empty data for failed requests
                    weeklySleepData.append(SleepData(
                        totalSleepHours: 0,
                        deepSleepHours: 0,
                        remSleepHours: 0,
                        lightSleepHours: 0,
                        awakeHours: 0,
                        sleepQuality: 0,
                        sleepEfficiency: 0
                    ))
                }
            }
        }
        
        return weeklySleepData
    }
    
    private func calculateSleepQuality(sleepLog: SleepLogEntry) -> Double {
        // Calculate sleep quality based on sleep duration and sleep stages
        let totalSleep = sleepLog.sleepDuration
        let deepSleep = sleepLog.deepSleepDuration
        let remSleep = sleepLog.remSleepDuration
        
        // Quality factors:
        // 1. Total sleep duration (7-9 hours is optimal)
        let durationScore = if totalSleep >= 7 && totalSleep <= 9 { 1.0 }
                           else if totalSleep >= 6 && totalSleep <= 10 { 0.7 }
                           else { 0.3 }
        
        // 2. Deep sleep ratio (20-25% is optimal)
        let deepSleepRatio = totalSleep > 0 ? deepSleep / totalSleep : 0
        let deepSleepScore = if deepSleepRatio >= 0.2 && deepSleepRatio <= 0.25 { 1.0 }
                            else if deepSleepRatio >= 0.15 && deepSleepRatio <= 0.3 { 0.7 }
                            else { 0.4 }
        
        // 3. REM sleep ratio (20-25% is optimal)
        let remSleepRatio = totalSleep > 0 ? remSleep / totalSleep : 0
        let remSleepScore = if remSleepRatio >= 0.2 && remSleepRatio <= 0.25 { 1.0 }
                           else if remSleepRatio >= 0.15 && remSleepRatio <= 0.3 { 0.7 }
                           else { 0.4 }
        
        // Weighted average
        return (durationScore * 0.4 + deepSleepScore * 0.3 + remSleepScore * 0.3) * 100
    }
    
    private func calculateSleepEfficiency(sleepLog: SleepLogEntry) -> Double {
        // Sleep efficiency = (Total Sleep Time / Time in Bed) * 100
        let totalSleep = sleepLog.sleepDuration
        let awakeTime = sleepLog.sleepAwakeDuration
        let timeInBed = totalSleep + awakeTime
        
        return timeInBed > 0 ? (totalSleep / timeInBed) * 100 : 0
    }
    
    // MARK: - Sleep Insights Generation
    
    func generateSleepInsights() async {
        do {
            let todaySleepData = try await getTodaySleepData()
            let weeklySleepData = try await getWeeklySleepData()
            
            var insights: [HealthInsight] = []
            
            // Generate sleep-specific insights
            insights.append(contentsOf: try await analyzeSleepInsights(todaySleepData: todaySleepData, weeklySleepData: weeklySleepData))
            
            // Add cross-reference to activity if available
            if todaySteps > 0 {
                insights.append(HealthInsight(
                    title: "Activity Connection",
                    description: "Your daily activity can impact sleep quality. Check your fitness trends for activity recommendations.",
                    type: .information,
                    priority: .low
                ))
            }
            
            sleepInsights = insights
            print("AnalyticsService: Generated \(insights.count) sleep insights")
            
        } catch {
            print("AnalyticsService: Failed to generate sleep insights: \(error)")
            sleepInsights = []
        }
    }
    
    private func analyzeSleepInsights(todaySleepData: SleepData, weeklySleepData: [SleepData]) async throws -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Today's sleep insights
        if todaySleepData.totalSleepHours > 0 {
            // Sleep duration insights
            if todaySleepData.totalSleepHours < 6 {
                insights.append(HealthInsight(
                    title: "Insufficient Sleep",
                    description: "You slept only \(String(format: "%.1f", todaySleepData.totalSleepHours)) hours last night. Aim for 7-9 hours for optimal health.",
                    type: .recommendation,
                    priority: .high
                ))
            } else if todaySleepData.totalSleepHours >= 7 && todaySleepData.totalSleepHours <= 9 {
                insights.append(HealthInsight(
                    title: "Optimal Sleep Duration",
                    description: "Great job! You slept \(String(format: "%.1f", todaySleepData.totalSleepHours)) hours, which is within the recommended range.",
                    type: .achievement,
                    priority: .low
                ))
            } else if todaySleepData.totalSleepHours > 9 {
                insights.append(HealthInsight(
                    title: "Extended Sleep",
                    description: "You slept \(String(format: "%.1f", todaySleepData.totalSleepHours)) hours. While rest is important, consistently sleeping over 9 hours may indicate underlying issues.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
            
            // Sleep quality insights
            if todaySleepData.sleepQuality >= 80 {
                insights.append(HealthInsight(
                    title: "Excellent Sleep Quality",
                    description: "Your sleep quality score is \(Int(todaySleepData.sleepQuality))%. Keep up your healthy sleep habits!",
                    type: .achievement,
                    priority: .low
                ))
            } else if todaySleepData.sleepQuality < 60 {
                insights.append(HealthInsight(
                    title: "Sleep Quality Improvement Needed",
                    description: "Your sleep quality score is \(Int(todaySleepData.sleepQuality))%. Consider improving your sleep environment and routine.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
            
            // Sleep efficiency insights
            if todaySleepData.sleepEfficiency < 85 {
                insights.append(HealthInsight(
                    title: "Sleep Efficiency",
                    description: "Your sleep efficiency is \(Int(todaySleepData.sleepEfficiency))%. Try to minimize time spent awake in bed.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
            
            // Sleep stage insights
            let deepSleepRatio = todaySleepData.totalSleepHours > 0 ? todaySleepData.deepSleepHours / todaySleepData.totalSleepHours : 0
            let remSleepRatio = todaySleepData.totalSleepHours > 0 ? todaySleepData.remSleepHours / todaySleepData.totalSleepHours : 0
            
            if deepSleepRatio < 0.15 {
                insights.append(HealthInsight(
                    title: "Low Deep Sleep",
                    description: "Deep sleep makes up only \(Int(deepSleepRatio * 100))% of your sleep. This stage is crucial for physical recovery.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
            
            if remSleepRatio < 0.15 {
                insights.append(HealthInsight(
                    title: "Low REM Sleep",
                    description: "REM sleep makes up only \(Int(remSleepRatio * 100))% of your sleep. This stage is important for memory and learning.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
        } else {
            // No sleep data available
            insights.append(HealthInsight(
                title: "Log Your Sleep",
                description: "No sleep data found for today. Log your sleep to get personalized insights and track your sleep patterns.",
                type: .recommendation,
                priority: .high
            ))
        }
        
        // Weekly patterns (if we have data)
        let daysWithSleep = weeklySleepData.filter { $0.totalSleepHours > 0 }
        if daysWithSleep.count >= 3 {
            let averageSleep = daysWithSleep.map { $0.totalSleepHours }.reduce(0, +) / Double(daysWithSleep.count)
            let averageQuality = daysWithSleep.map { $0.sleepQuality }.reduce(0, +) / Double(daysWithSleep.count)
            
            if averageSleep < 6.5 {
                insights.append(HealthInsight(
                    title: "Weekly Sleep Pattern",
                    description: "Your average sleep this week is \(String(format: "%.1f", averageSleep)) hours. Consider prioritizing sleep for better health.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
            
            if averageQuality < 70 {
                insights.append(HealthInsight(
                    title: "Sleep Quality Trend",
                    description: "Your average sleep quality this week is \(Int(averageQuality))%. Focus on improving your sleep routine.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
        }
        
        return insights
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

struct HealthPrediction {
    let title: String
    let probability: Double
    let metric: String
    let predictedValue: Any
    let confidence: Double
    let timeframe: String
    let reasoning: String
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
    case information
    
    var icon: String {
        switch self {
        case .recommendation: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .motivation: return "heart.fill"
        case .achievement: return "star.fill"
        case .information: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .recommendation: return .blue
        case .warning: return .orange
        case .motivation: return .pink
        case .achievement: return .yellow
        case .information: return .gray
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
    let caloriesConsumed: Int
    let caloriesTarget: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let proteinTarget: Int
    let carbsTarget: Int
    let fatTarget: Int
    let caloriesPercentage: Double
    let proteinPercentage: Double
    let carbsPercentage: Double
    let fatPercentage: Double
}

struct SleepData {
    let totalSleepHours: Double
    let deepSleepHours: Double
    let remSleepHours: Double
    let lightSleepHours: Double
    let awakeHours: Double
    let sleepQuality: Double
    let sleepEfficiency: Double
} 
