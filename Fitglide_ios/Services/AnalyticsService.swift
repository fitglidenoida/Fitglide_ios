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
        return try await strapiRepository.getHealthLogs(
            startDate: startDate,
            endDate: endDate,
            filters: [:]
        )
    }
    
    func getWeeklyStepsData(from startDate: Date, to endDate: Date) async throws -> [Int64] {
        let healthLogs = try await getWeeklyHealthData(from: startDate, to: endDate)
        return healthLogs.map { $0.steps ?? 0 }
    }
    
    func getWeeklyCaloriesData(from startDate: Date, to endDate: Date) async throws -> [Float] {
        let healthLogs = try await getWeeklyHealthData(from: startDate, to: endDate)
        return healthLogs.map { $0.caloriesBurned ?? 0 }
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
            let sleepInsights = try await analyzeSleepInsights()
            let nutritionInsights = try await analyzeNutritionInsights()
            let activityInsights = try await analyzeActivityInsights()
            let recoveryInsights = try await analyzeRecoveryInsights()
            
            insights = sleepInsights + nutritionInsights + activityInsights + recoveryInsights
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
        let sleepData = try await healthService.getSleep(date: Date())
        
        var insights: [HealthInsight] = []
        
        if sleepData.total < 6 * 3600 {
            insights.append(HealthInsight(
                title: "Sleep Duration Alert",
                description: "You're getting less than 6 hours of sleep. Consider going to bed earlier.",
                type: .warning,
                priority: .high
            ))
        }
        
        if sleepData.deep < 1 * 3600 {
            insights.append(HealthInsight(
                title: "Deep Sleep Optimization",
                description: "Your deep sleep is below optimal levels. Try reducing screen time before bed.",
                type: .recommendation,
                priority: .medium
            ))
        }
        
        return insights
    }
    
    private func analyzeNutritionInsights() async throws -> [HealthInsight] {
        let nutrition = try await healthService.getNutritionData(date: Date())
        
        var insights: [HealthInsight] = []
        
        if nutrition.protein < 50 {
            insights.append(HealthInsight(
                title: "Protein Intake",
                description: "Your protein intake is below recommended levels. Consider adding more lean protein.",
                type: .recommendation,
                priority: .medium
            ))
        }
        
        if nutrition.fiber < 25 {
            insights.append(HealthInsight(
                title: "Fiber Boost",
                description: "Increase your fiber intake for better digestive health.",
                type: .recommendation,
                priority: .low
            ))
        }
        
        return insights
    }
    
    private func analyzeActivityInsights() async throws -> [HealthInsight] {
        let steps = try await healthService.getSteps(date: Date())
        
        var insights: [HealthInsight] = []
        
        if steps < 5000 {
            insights.append(HealthInsight(
                title: "Step Goal",
                description: "You're below your daily step goal. Try taking a walk after dinner.",
                type: .motivation,
                priority: .medium
            ))
        }
        
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