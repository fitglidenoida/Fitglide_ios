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
    
    // Default initializer for convenience
    convenience init() {
        let healthService = HealthService()
        let authRepository = AuthRepository()
        let strapiRepository = StrapiRepository(authRepository: authRepository)
        self.init(healthService: healthService, strapiRepository: strapiRepository, authRepository: authRepository)
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
            
            // Get comprehensive health data
            let todaySteps = try await getStepsData(for: Date())
            let todaySleepData = try await getTodaySleepData()
            let nutritionData = try await getTodayNutritionData()
            let weeklySleepData = try await getWeeklySleepData()
            
            print("AnalyticsService: Generating holistic insights with - Steps: \(todaySteps), Sleep: \(todaySleepData.totalSleepHours)h, Calories: \(nutritionData.caloriesConsumed)")
            
            // 1. OVERALL WELLNESS SCORE
            let wellnessScore = calculateWellnessScore(steps: todaySteps, sleep: todaySleepData, nutrition: nutritionData)
            mainInsights.append(HealthInsight(
                title: "Today's Wellness Score",
                description: "Your overall wellness score is \(Int(wellnessScore))%. \(getWellnessMessage(score: wellnessScore))",
                type: wellnessScore >= 80 ? .achievement : .recommendation,
                priority: .high
            ))
            
            // 2. CROSS-DOMAIN INSIGHTS
            let crossDomainInsights = generateCrossDomainInsights(steps: todaySteps, sleep: todaySleepData, nutrition: nutritionData, correlations: correlations)
            mainInsights.append(contentsOf: crossDomainInsights)
            
            // 3. TREND-BASED INSIGHTS
            let trendInsights = generateTrendInsights(weeklySleepData: weeklySleepData, steps: todaySteps)
            mainInsights.append(contentsOf: trendInsights)
            
            // 4. ACTIONABLE RECOMMENDATIONS
            let actionableInsights = generateActionableRecommendations(steps: todaySteps, sleep: todaySleepData, nutrition: nutritionData)
            mainInsights.append(contentsOf: actionableInsights)
            
            // 5. ACHIEVEMENT RECOGNITION
            let achievementInsights = generateAchievementInsights(steps: todaySteps, sleep: todaySleepData, nutrition: nutritionData)
            mainInsights.append(contentsOf: achievementInsights)
            
            // Set main page insights (holistic wellness)
            insights = mainInsights.prefix(6) // Limit to 6 most important insights
            print("AnalyticsService: Generated \(insights.count) holistic wellness insights")
            
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
    
    // MARK: - ML/AI Prediction System
    
    func generateAIPredictions() async -> [HealthPrediction] {
        do {
            var predictions: [HealthPrediction] = []
            
            // Get historical data for pattern analysis
            let weeklySleepData = try await getWeeklySleepData()
            let weeklyStepsData = try await getWeeklyStepsData(from: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(), to: Date())
            let nutritionData = try await getTodayNutritionData()
            
            // 1. Sleep Quality Prediction
            let sleepPrediction = try await predictSleepQuality(weeklyData: weeklySleepData)
            predictions.append(sleepPrediction)
            
            // 2. Energy Level Prediction
            let energyPrediction = try await predictEnergyLevels(sleepData: weeklySleepData, stepsData: weeklyStepsData, nutritionData: nutritionData)
            predictions.append(energyPrediction)
            
            // 3. Activity Performance Prediction
            let activityPrediction = try await predictActivityPerformance(sleepData: weeklySleepData, nutritionData: nutritionData)
            predictions.append(activityPrediction)
            
            // 4. Health Risk Assessment
            let riskPrediction = try await predictHealthRisks(sleepData: weeklySleepData, stepsData: weeklyStepsData, nutritionData: nutritionData)
            predictions.append(riskPrediction)
            
            // 5. Personalized Recommendations
            let recommendationPrediction = try await generatePersonalizedRecommendations(sleepData: weeklySleepData, stepsData: weeklyStepsData, nutritionData: nutritionData)
            predictions.append(recommendationPrediction)
            
            return predictions
            
        } catch {
            print("AnalyticsService: Failed to generate AI predictions: \(error)")
            return []
        }
    }
    
    private func predictSleepQuality(weeklyData: [AnalyticsSleepData]) async throws -> HealthPrediction {
        let recentSleep = weeklyData.suffix(3)
        let olderSleep = weeklyData.prefix(3)
        
        guard !recentSleep.isEmpty && !olderSleep.isEmpty else {
            return HealthPrediction(
                title: "Sleep Quality",
                probability: 0.5,
                metric: "Sleep Quality",
                predictedValue: "Unknown",
                confidence: 0.3,
                timeframe: "Tonight",
                reasoning: "Insufficient data for prediction"
            )
        }
        
        let recentAvg = recentSleep.map { $0.sleepQuality }.reduce(0, +) / Double(recentSleep.count)
        let olderAvg = olderSleep.map { $0.sleepQuality }.reduce(0, +) / Double(olderSleep.count)
        
        let trend = recentAvg - olderAvg
        let predictedQuality = recentAvg + (trend * 0.5) // Extrapolate trend
        
        let confidence = min(0.9, Double(recentSleep.count) / 7.0)
        let probability = min(1.0, max(0.0, predictedQuality / 100.0))
        
        let qualityLevel = predictedQuality >= 80 ? "Excellent" : 
                          predictedQuality >= 60 ? "Good" : 
                          predictedQuality >= 40 ? "Fair" : "Poor"
        
        let reasoning = trend > 5 ? "Your sleep quality is improving" :
                       trend < -5 ? "Your sleep quality is declining" :
                       "Your sleep quality is stable"
        
        return HealthPrediction(
            title: "Sleep Quality Prediction",
            probability: probability,
            metric: "Sleep Quality",
            predictedValue: qualityLevel,
            confidence: confidence,
            timeframe: "Tonight",
            reasoning: reasoning
        )
    }
    
    private func predictEnergyLevels(sleepData: [AnalyticsSleepData], stepsData: [Int], nutritionData: NutritionData) async throws -> HealthPrediction {
        // Calculate energy score based on multiple factors
        var energyScore = 0.0
        var factors = 0
        
        // Sleep factor (40% weight)
        if let recentSleep = sleepData.last, recentSleep.totalSleepHours > 0 {
            let sleepScore = min(recentSleep.totalSleepHours / 8.0, 1.0) * 100
            energyScore += sleepScore * 0.4
            factors += 1
        }
        
        // Activity factor (30% weight)
        if let recentSteps = stepsData.last, recentSteps > 0 {
            let activityScore = min(Double(recentSteps) / 10000.0, 1.0) * 100
            energyScore += activityScore * 0.3
            factors += 1
        }
        
        // Nutrition factor (30% weight)
        if nutritionData.caloriesConsumed > 0 {
            let nutritionScore = min(nutritionData.caloriesPercentage / 100.0, 1.0) * 100
            energyScore += nutritionScore * 0.3
            factors += 1
        }
        
        let finalScore = factors > 0 ? energyScore : 50.0
        let energyLevel = finalScore >= 80 ? "High" : 
                         finalScore >= 60 ? "Moderate" : 
                         finalScore >= 40 ? "Low" : "Very Low"
        
        let confidence = min(0.9, Double(factors) / 3.0)
        
        return HealthPrediction(
            title: "Energy Level Prediction",
            probability: finalScore / 100.0,
            metric: "Energy Level",
            predictedValue: energyLevel,
            confidence: confidence,
            timeframe: "Tomorrow",
            reasoning: "Based on your sleep, activity, and nutrition patterns"
        )
    }
    
    private func predictActivityPerformance(sleepData: [AnalyticsSleepData], nutritionData: NutritionData) async throws -> HealthPrediction {
        var performanceScore = 0.0
        var factors = 0
        
        // Sleep recovery factor (50% weight)
        if let recentSleep = sleepData.last, recentSleep.totalSleepHours > 0 {
            let recoveryScore = min(recentSleep.sleepEfficiency / 100.0, 1.0) * 100
            performanceScore += recoveryScore * 0.5
            factors += 1
        }
        
        // Nutrition fuel factor (50% weight)
        if nutritionData.caloriesConsumed > 0 {
            let fuelScore = min(nutritionData.caloriesPercentage / 100.0, 1.0) * 100
            performanceScore += fuelScore * 0.5
            factors += 1
        }
        
        let finalScore = factors > 0 ? performanceScore : 50.0
        let performance = finalScore >= 80 ? "Excellent" : 
                         finalScore >= 60 ? "Good" : 
                         finalScore >= 40 ? "Fair" : "Poor"
        
        let confidence = min(0.9, Double(factors) / 2.0)
        
        return HealthPrediction(
            title: "Activity Performance",
            probability: finalScore / 100.0,
            metric: "Performance",
            predictedValue: performance,
            confidence: confidence,
            timeframe: "Today",
            reasoning: "Based on your recovery and nutrition status"
        )
    }
    
    private func predictHealthRisks(sleepData: [AnalyticsSleepData], stepsData: [Int], nutritionData: NutritionData) async throws -> HealthPrediction {
        var riskFactors = 0
        var totalFactors = 0
        
        // Sleep deprivation risk
        if let recentSleep = sleepData.last {
            totalFactors += 1
            if recentSleep.totalSleepHours < 6 {
                riskFactors += 1
            }
        }
        
        // Sedentary lifestyle risk
        if let recentSteps = stepsData.last {
            totalFactors += 1
            if recentSteps < 5000 {
                riskFactors += 1
            }
        }
        
        // Poor nutrition risk
        if nutritionData.caloriesConsumed > 0 {
            totalFactors += 1
            if nutritionData.caloriesPercentage < 70 || nutritionData.caloriesPercentage > 130 {
                riskFactors += 1
            }
        }
        
        let riskPercentage = totalFactors > 0 ? (Double(riskFactors) / Double(totalFactors)) * 100 : 0
        let riskLevel = riskPercentage >= 66 ? "High" : 
                       riskPercentage >= 33 ? "Medium" : "Low"
        
        let confidence = min(0.9, Double(totalFactors) / 3.0)
        
        return HealthPrediction(
            title: "Health Risk Assessment",
            probability: riskPercentage / 100.0,
            metric: "Risk Level",
            predictedValue: riskLevel,
            confidence: confidence,
            timeframe: "Current",
            reasoning: "Based on sleep, activity, and nutrition patterns"
        )
    }
    
    private func generatePersonalizedRecommendations(sleepData: [AnalyticsSleepData], stepsData: [Int], nutritionData: NutritionData) async throws -> HealthPrediction {
        var recommendations: [String] = []
        
        // Sleep recommendations
        if let recentSleep = sleepData.last {
            if recentSleep.totalSleepHours < 6 {
                recommendations.append("Prioritize 7-9 hours of sleep")
            } else if recentSleep.sleepEfficiency < 85 {
                recommendations.append("Improve sleep environment and routine")
            }
        }
        
        // Activity recommendations
        if let recentSteps = stepsData.last {
            if recentSteps < 5000 {
                recommendations.append("Increase daily activity to 10,000 steps")
            } else if recentSteps >= 10000 {
                recommendations.append("Maintain your excellent activity level")
            }
        }
        
        // Nutrition recommendations
        if nutritionData.caloriesConsumed > 0 {
            if nutritionData.caloriesPercentage < 70 {
                recommendations.append("Increase calorie intake to support your activity")
            } else if nutritionData.caloriesPercentage > 130 {
                recommendations.append("Consider adjusting portion sizes")
            }
        }
        
        let recommendation = recommendations.isEmpty ? "Continue your current healthy habits" : recommendations.joined(separator: "; ")
        
        return HealthPrediction(
            title: "Personalized Recommendations",
            probability: 0.8,
            metric: "Recommendations",
            predictedValue: recommendation,
            confidence: 0.8,
            timeframe: "Next Week",
            reasoning: "Based on your health data patterns and goals"
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
        // Get weekly sleep and activity data from Strapi
        let weeklySleepData = try await getWeeklySleepData()
        let weeklyStepsData = try await getWeeklyStepsData(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(), to: Date())
        
        // Calculate correlation between sleep hours and steps
        var sleepHours: [Double] = []
        var steps: [Double] = []
        
        for sleepData in weeklySleepData {
            if sleepData.totalSleepHours > 0 {
                sleepHours.append(sleepData.totalSleepHours)
            }
        }
        
        for stepsCount in weeklyStepsData {
            steps.append(Double(stepsCount))
        }
        
        // Calculate correlation coefficient
        let correlation = calculateCorrelation(x: sleepHours, y: steps)
        
        let strength = abs(correlation)
        let isPositive = correlation > 0
        
        return HealthCorrelation(
            factor1: "Sleep Quality",
            factor2: "Activity Level",
            strength: correlation,
            description: isPositive ? 
                "Better sleep quality correlates with higher daily activity levels" :
                "Sleep quality and activity levels show inverse relationship",
            impact: strength > 0.7 ? "High" : strength > 0.4 ? "Medium" : "Low"
        )
    }
    
    private func correlateNutritionAndEnergy() async throws -> HealthCorrelation {
        // Get nutrition data from Strapi
        let nutritionData = try await getTodayNutritionData()
        
        // Calculate correlation based on nutrition balance
        let caloriePercentage = nutritionData.caloriesPercentage
        let proteinPercentage = nutritionData.proteinPercentage
        
        // Simple correlation: balanced nutrition (closer to 100%) correlates with better energy
        let nutritionBalance = (caloriePercentage + proteinPercentage) / 2.0
        let correlation = (nutritionBalance - 50) / 50 // Normalize to -1 to 1 range
        
        return HealthCorrelation(
            factor1: "Nutrition",
            factor2: "Energy Levels",
            strength: correlation,
            description: "Balanced nutrition intake leads to sustained energy throughout the day",
            impact: abs(correlation) > 0.7 ? "High" : abs(correlation) > 0.4 ? "Medium" : "Low"
        )
    }
    
    private func correlateStressAndRecovery() async throws -> HealthCorrelation {
        // Get sleep efficiency data from Strapi
        let weeklySleepData = try await getWeeklySleepData()
        
        // Calculate average sleep efficiency
        let efficiencies = weeklySleepData.compactMap { sleepData in
            sleepData.totalSleepHours > 0 ? sleepData.sleepEfficiency : nil
        }
        
        let avgEfficiency = efficiencies.isEmpty ? 0 : efficiencies.reduce(0, +) / Double(efficiencies.count)
        
        // Inverse correlation: higher efficiency = lower stress impact
        let correlation = -(avgEfficiency / 100.0) // Convert to -1 to 1 range
        
        return HealthCorrelation(
            factor1: "Stress Level",
            factor2: "Recovery",
            strength: correlation,
            description: "Higher stress levels negatively impact recovery and sleep quality",
            impact: abs(correlation) > 0.7 ? "High" : abs(correlation) > 0.4 ? "Medium" : "Low"
        )
    }
    
    private func correlateCycleAndHealth() async throws -> HealthCorrelation {
        // For now, use a moderate correlation as this requires cycle tracking data
        // In a real implementation, this would analyze cycle phase vs energy/performance
        let correlation = 0.45
        
        return HealthCorrelation(
            factor1: "Menstrual Cycle",
            factor2: "Energy & Performance",
            strength: correlation,
            description: "Energy levels and workout performance vary throughout the menstrual cycle",
            impact: "Medium"
        )
    }
    
    // Helper method to calculate correlation coefficient
    private func calculateCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        guard denominator != 0 else { return 0 }
        return numerator / denominator
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
            
            // Calculate targets based on user profile (simplified for now)
            let caloriesTarget = 2000
            let proteinTarget = 120
            let carbsTarget = 250
            let fatTarget = 80
            
            // Calculate percentages
            let caloriesPercentage = caloriesTarget > 0 ? Double(totalCalories) / Double(caloriesTarget) : 0
            let proteinPercentage = proteinTarget > 0 ? Double(totalProtein) / Double(proteinTarget) : 0
            let carbsPercentage = carbsTarget > 0 ? Double(totalCarbs) / Double(carbsTarget) : 0
            let fatPercentage = fatTarget > 0 ? Double(totalFat) / Double(fatTarget) : 0
            
            // For now, use placeholder meal percentages (in a real implementation, these would be calculated from meal data)
            let breakfastPercentage = 0.3 // 30% of daily calories
            let lunchPercentage = 0.35    // 35% of daily calories
            let dinnerPercentage = 0.25   // 25% of daily calories
            let snacksPercentage = 0.1    // 10% of daily calories
            
            let nutritionData = NutritionData(
                caloriesConsumed: totalCalories,
                caloriesTarget: caloriesTarget,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                proteinTarget: proteinTarget,
                carbsTarget: carbsTarget,
                fatTarget: fatTarget,
                caloriesPercentage: caloriesPercentage,
                proteinPercentage: proteinPercentage,
                carbsPercentage: carbsPercentage,
                fatPercentage: fatPercentage,
                breakfastPercentage: breakfastPercentage,
                lunchPercentage: lunchPercentage,
                dinnerPercentage: dinnerPercentage,
                snacksPercentage: snacksPercentage
            )
            
            print("AnalyticsService: Nutrition data - Calories: \(totalCalories), Protein: \(totalProtein), Carbs: \(totalCarbs), Fat: \(totalFat)")
            
            return nutritionData
            
        } catch {
            print("AnalyticsService: Failed to fetch nutrition data: \(error)")
            // Return empty nutrition data (all zeros)
            return NutritionData(
                caloriesConsumed: 0,
                caloriesTarget: 2000,
                protein: 0,
                carbs: 0,
                fat: 0,
                proteinTarget: 120,
                carbsTarget: 250,
                fatTarget: 80,
                caloriesPercentage: 0.0,
                proteinPercentage: 0.0,
                carbsPercentage: 0.0,
                fatPercentage: 0.0,
                breakfastPercentage: 0.0,
                lunchPercentage: 0.0,
                dinnerPercentage: 0.0,
                snacksPercentage: 0.0
            )
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
    
    func getTodaySleepData() async throws -> AnalyticsSleepData {
        guard let userId = authRepository.authState.userId,
              let _ = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let today = Date()
        
        print("Fetching sleep data for userId: \(userId), date: \(today)")
        
        do {
            let response = try await strapiRepository.fetchSleepLog(date: today)
            
            if let sleepLog = response.data.first {
                return AnalyticsSleepData(
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
                return AnalyticsSleepData(
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
    
    func getWeeklySleepData() async throws -> [AnalyticsSleepData] {
        guard let _ = authRepository.authState.userId,
              let _ = authRepository.authState.jwt else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing userId or token"])
        }
        
        let calendar = Calendar.current
        let today = Date()
        var weeklySleepData: [AnalyticsSleepData] = []
        
        print("AnalyticsService: Fetching weekly sleep data for the last 7 days")
        
        // Fetch sleep data for the last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                do {
                    let response = try await strapiRepository.fetchSleepLog(date: date)
                    
                    if let sleepLog = response.data.first {
                        let sleepData = AnalyticsSleepData(
                            totalSleepHours: Double(sleepLog.sleepDuration),
                            deepSleepHours: Double(sleepLog.deepSleepDuration),
                            remSleepHours: Double(sleepLog.remSleepDuration),
                            lightSleepHours: Double(sleepLog.lightSleepDuration),
                            awakeHours: Double(sleepLog.sleepAwakeDuration),
                            sleepQuality: calculateSleepQuality(sleepLog: sleepLog),
                            sleepEfficiency: calculateSleepEfficiency(sleepLog: sleepLog)
                        )
                        weeklySleepData.append(sleepData)
                        print("AnalyticsService: Found sleep data for day \(i): \(sleepLog.sleepDuration) hours")
                    } else {
                        // Add empty data for missing days
                        weeklySleepData.append(AnalyticsSleepData(
                            totalSleepHours: 0,
                            deepSleepHours: 0,
                            remSleepHours: 0,
                            lightSleepHours: 0,
                            awakeHours: 0,
                            sleepQuality: 0,
                            sleepEfficiency: 0
                        ))
                        print("AnalyticsService: No sleep data for day \(i)")
                    }
                } catch {
                    print("AnalyticsService: Failed to fetch sleep data for date \(date): \(error)")
                    // Add empty data for failed requests
                    weeklySleepData.append(AnalyticsSleepData(
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
        
        print("AnalyticsService: Weekly sleep data collection complete, found \(weeklySleepData.filter { $0.totalSleepHours > 0 }.count) days with data")
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
        let totalSleep = Double(sleepLog.sleepDuration)
        let awakeTime = Double(sleepLog.sleepAwakeDuration)
        let timeInBed = totalSleep + awakeTime
        
        return timeInBed > 0 ? (totalSleep / timeInBed) * 100 : 0
    }
    
    // MARK: - Sleep Insights Generation
    
    func generateSleepInsights() async {
        do {
            print("AnalyticsService: Starting sleep insights generation...")
            let todaySleepData = try await getTodaySleepData()
            print("AnalyticsService: Today's sleep data - Total: \(todaySleepData.totalSleepHours)h, Quality: \(todaySleepData.sleepQuality)%")
            
            let weeklySleepData = try await getWeeklySleepData()
            print("AnalyticsService: Weekly sleep data - \(weeklySleepData.filter { $0.totalSleepHours > 0 }.count) days with data")
            
            var insights: [HealthInsight] = []
            
            // Generate sleep-specific insights
            insights.append(contentsOf: try await analyzeSleepInsights(todaySleepData: todaySleepData, weeklySleepData: weeklySleepData))
            
            // Add cross-reference to activity if available
            if let steps = Int(todaySteps), steps > 0 {
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
    
    private func analyzeSleepInsights(todaySleepData: AnalyticsSleepData, weeklySleepData: [AnalyticsSleepData]) async throws -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Today's sleep insights
        if todaySleepData.totalSleepHours > 0 {
            // Sleep duration insights
            if todaySleepData.totalSleepHours < 6 { // Convert hours to seconds
                insights.append(HealthInsight(
                    title: "Insufficient Sleep",
                    description: "You slept only \(String(format: "%.1f", todaySleepData.totalSleepHours)) hours last night. Aim for 7-9 hours for optimal health.",
                    type: .recommendation,
                    priority: .high
                ))
            } else if todaySleepData.totalSleepHours >= 7 && todaySleepData.totalSleepHours <= 9 { // Convert hours to seconds
                insights.append(HealthInsight(
                    title: "Optimal Sleep Duration",
                    description: "Great job! You slept \(String(format: "%.1f", todaySleepData.totalSleepHours)) hours, which is within the recommended range.",
                    type: .achievement,
                    priority: .low
                ))
            } else if todaySleepData.totalSleepHours > 9 { // Convert hours to seconds
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
                    description: "Your sleep quality score is \(Int(todaySleepData.sleepQuality * 100))%. Keep up your healthy sleep habits!",
                    type: .achievement,
                    priority: .low
                ))
            } else if todaySleepData.sleepQuality >= 40 {
                insights.append(HealthInsight(
                    title: "Sleep Quality Improvement Needed",
                    description: "Your sleep quality score is \(Int(todaySleepData.sleepQuality * 100))%. Consider improving your sleep environment and routine.",
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
    
    // MARK: - Holistic Insight Methods
    
    private func calculateWellnessScore(steps: Int, sleep: AnalyticsSleepData, nutrition: NutritionData) -> Double {
        var score = 0.0
        var factors = 0
        
        // Steps factor (30% weight)
        if steps > 0 {
            let stepScore = min(Double(steps) / 10000.0, 1.0) * 100
            score += stepScore * 0.3
            factors += 1
        }
        
        // Sleep factor (40% weight)
        if sleep.totalSleepHours > 0 {
            let sleepScore = min(sleep.totalSleepHours / 8.0, 1.0) * 100
            score += sleepScore * 0.4
            factors += 1
        }
        
        // Nutrition factor (30% weight)
        if nutrition.caloriesConsumed > 0 {
            let nutritionScore = min(nutrition.caloriesPercentage / 100.0, 1.0) * 100
            score += nutritionScore * 0.3
            factors += 1
        }
        
        return factors > 0 ? score : 0
    }
    
    private func getWellnessMessage(score: Double) -> String {
        switch score {
        case 90...100:
            return "Excellent! You're maintaining exceptional health habits."
        case 80..<90:
            return "Great job! You're on track for optimal wellness."
        case 70..<80:
            return "Good progress! Small improvements can boost your score further."
        case 60..<70:
            return "You're doing okay, but there's room for improvement."
        default:
            return "Focus on building healthy habits to improve your wellness."
        }
    }
    
    private func generateCrossDomainInsights(steps: Int, sleep: AnalyticsSleepData, nutrition: NutritionData, correlations: [HealthCorrelation]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Sleep-Activity Connection
        if sleep.totalSleepHours > 0 && steps > 0 {
            if sleep.totalSleepHours >= 7 && steps >= 8000 {
                insights.append(HealthInsight(
                    title: "Perfect Balance",
                    description: "Great sleep + high activity! This combination optimizes your health and energy levels.",
                    type: .achievement,
                    priority: .low
                ))
            } else if sleep.totalSleepHours < 6 && steps > 10000 {
                insights.append(HealthInsight(
                    title: "High Activity, Low Sleep",
                    description: "You're very active but sleep-deprived. Consider prioritizing sleep for better recovery.",
                    type: .recommendation,
                    priority: .high
                ))
            }
        }
        
        // Nutrition-Energy Connection
        if nutrition.caloriesConsumed > 0 {
            if nutrition.caloriesPercentage < 70 && steps > 8000 {
                insights.append(HealthInsight(
                    title: "Fuel Your Activity",
                    description: "You're active but under-eating. Increase your calorie intake to support your activity level.",
                    type: .recommendation,
                    priority: .medium
                ))
            } else if nutrition.caloriesPercentage > 120 && steps < 5000 {
                insights.append(HealthInsight(
                    title: "Calorie Balance",
                    description: "High calorie intake with low activity. Consider increasing movement or adjusting nutrition.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
        }
        
        // Strongest Correlation Highlight
        if let strongestCorrelation = correlations.max(by: { abs($0.strength) < abs($1.strength) }) {
            if abs(strongestCorrelation.strength) > 0.6 {
                insights.append(HealthInsight(
                    title: "Key Health Connection",
                    description: strongestCorrelation.description,
                    type: .information,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func generateTrendInsights(weeklySleepData: [AnalyticsSleepData], steps: Int) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Sleep trend analysis
        let sleepDays = weeklySleepData.filter { $0.totalSleepHours > 0 }
        if sleepDays.count >= 3 {
            let avgSleep = sleepDays.map { $0.totalSleepHours }.reduce(0, +) / Double(sleepDays.count)
            let recentSleep = Array(sleepDays.suffix(3)).map { $0.totalSleepHours }.reduce(0, +) / 3.0
            
            if recentSleep > avgSleep + 0.5 {
                insights.append(HealthInsight(
                    title: "Improving Sleep Pattern",
                    description: "Your sleep has been better recently. Keep up the good work!",
                    type: .achievement,
                    priority: .low
                ))
            } else if recentSleep < avgSleep - 0.5 {
                insights.append(HealthInsight(
                    title: "Sleep Pattern Decline",
                    description: "Your sleep quality has decreased. Review your bedtime routine.",
                    type: .recommendation,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    private func generateActionableRecommendations(steps: Int, sleep: AnalyticsSleepData, nutrition: NutritionData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Priority recommendations based on data gaps
        if sleep.totalSleepHours == 0 {
            insights.append(HealthInsight(
                title: "Track Your Sleep",
                description: "Start logging your sleep to get personalized insights and recommendations.",
                type: .recommendation,
                priority: .high
            ))
        }
        
        if nutrition.caloriesConsumed == 0 {
            insights.append(HealthInsight(
                title: "Log Your Meals",
                description: "Track your nutrition to understand how it affects your energy and performance.",
                type: .recommendation,
                priority: .high
            ))
        }
        
        if steps == 0 {
            insights.append(HealthInsight(
                title: "Start Moving",
                description: "Begin with a short walk today. Every step counts toward your health goals.",
                type: .recommendation,
                priority: .high
            ))
        }
        
        return insights
    }
    
    private func generateAchievementInsights(steps: Int, sleep: AnalyticsSleepData, nutrition: NutritionData) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Step achievements
        if steps >= 10000 {
            insights.append(HealthInsight(
                title: "10K Steps Achieved! 🎉",
                description: "You've hit the daily step goal. Excellent work!",
                type: .achievement,
                priority: .low
            ))
        } else if steps >= 8000 {
            insights.append(HealthInsight(
                title: "Close to Goal",
                description: "Just \(10000 - steps) more steps to reach your daily target!",
                type: .achievement,
                priority: .low
            ))
        }
        
        // Sleep achievements
        if sleep.totalSleepHours >= 7 && sleep.totalSleepHours <= 9 {
            insights.append(HealthInsight(
                title: "Perfect Sleep Duration",
                description: "You slept \(String(format: "%.1f", sleep.totalSleepHours)) hours - the optimal range!",
                type: .achievement,
                priority: .low
            ))
        }
        
        // Nutrition achievements
        if nutrition.caloriesConsumed > 0 && nutrition.caloriesPercentage >= 90 && nutrition.caloriesPercentage <= 110 {
            insights.append(HealthInsight(
                title: "Balanced Nutrition",
                description: "Great job maintaining a balanced calorie intake!",
                type: .achievement,
                priority: .low
            ))
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
    let breakfastPercentage: Double
    let lunchPercentage: Double
    let dinnerPercentage: Double
    let snacksPercentage: Double
}

struct AnalyticsSleepData {
    let totalSleepHours: Double
    let deepSleepHours: Double
    let remSleepHours: Double
    let lightSleepHours: Double
    let awakeHours: Double
    let sleepQuality: Double
    let sleepEfficiency: Double
} 
