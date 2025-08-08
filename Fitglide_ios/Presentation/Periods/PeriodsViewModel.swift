//
//  PeriodsViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
class PeriodsViewModel: ObservableObject {
    @Published var periods: [PeriodEntry] = []
    @Published var symptoms: [SymptomEntry] = []
    @Published var cycleInsights: [String] = []
    @Published var healthCorrelations: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Settings
    @Published var periodReminders = true
    @Published var fertilityAlerts = true
    @Published var symptomReminders = true
    
    // Computed properties
    var currentCycleDay: Int {
        guard let lastPeriod = periods.last else { return 0 }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: Date()).day ?? 0
        return daysSinceLastPeriod + 1
    }
    
    var nextPeriodDate: Date {
        return predictNextPeriod().predictedDate
    }
    
    var cycleProgress: Double {
        guard let lastPeriod = periods.last else { return 0.0 }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: Date()).day ?? 0
        let progress = Double(daysSinceLastPeriod) / Double(averageCycleLength)
        return max(0.0, min(progress, 1.0)) // Ensure value is between 0 and 1
    }
    
    var cycleProgressPercentage: Double {
        return cycleProgress * 100
    }
    
    var isInFertilityWindow: Bool {
        let fertilityPrediction = predictFertilityWindow()
        let today = Date()
        return today >= fertilityPrediction.fertileStart && today <= fertilityPrediction.fertileEnd
    }
    
    var nextFertilityWindow: Date {
        return predictFertilityWindow().fertileStart
    }
    
    var recentPeriods: [PeriodEntry] {
        return Array(periods.suffix(6))
    }
    
    var todaySymptoms: [SymptomEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return symptoms.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var symptomHistory: [SymptomHistoryEntry] {
        let groupedSymptoms = Dictionary(grouping: symptoms) { symptom in
            Calendar.current.startOfDay(for: symptom.date)
        }
        
        return groupedSymptoms.map { date, symptoms in
            SymptomHistoryEntry(
                id: UUID().uuidString,
                date: date,
                symptoms: symptoms.map { $0.name }
            )
        }.sorted { $0.date > $1.date }
    }
    
    var averageCycleLength: Int {
        guard periods.count >= 2 else { return 28 }
        let cycleLengths = zip(periods, periods.dropFirst()).map { period1, period2 in
            Calendar.current.dateComponents([.day], from: period1.startDate, to: period2.startDate).day ?? 28
        }
        return cycleLengths.isEmpty ? 28 : Int(Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count))
    }
    
    var averagePeriodLength: Int {
        guard !periods.isEmpty else { return 5 }
        let totalDays = periods.reduce(0) { $0 + $1.duration }
        return totalDays / periods.count
    }
    
    var lastPeriodStart: Date {
        return periods.last?.startDate ?? Date()
    }
    
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        
        // Load real data instead of sample data
        Task {
            await fetchPeriodsData()
        }
    }
    
    func addPeriod(startDate: Date, duration: Int, flow: FlowIntensity) {
        let newPeriod = PeriodEntry(
            id: UUID().uuidString,
            startDate: startDate,
            duration: duration,
            flow: flow
        )
        periods.append(newPeriod)
        generateInsights()
        
        // Save to Strapi
        Task {
            await savePeriodData()
        }
    }
    
    func addSymptom(name: String, severity: SymptomSeverity, date: Date = Date()) {
        let newSymptom = SymptomEntry(
            id: UUID().uuidString,
            name: name,
            severity: severity,
            date: date,
            icon: iconForSymptom(name)
        )
        symptoms.append(newSymptom)
        generateInsights()
    }
    
    func isPeriodDay(day: Int) -> Bool {
        // Check if the given day (1-35) corresponds to a period day based on real data
        guard let lastPeriod = periods.last else { return false }
        
        let today = Date()
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: today).day ?? 0
        let currentCycleDay = daysSinceLastPeriod + 1
        
        // Calculate which cycle day this represents in the 35-day calendar
        let cycleStartDay = max(1, currentCycleDay - 17) // Center the current day around day 18
        let calendarDay = day + cycleStartDay - 1
        
        // Check if this calendar day falls within the last period
        let periodStartDay = currentCycleDay - lastPeriod.duration + 1
        let periodEndDay = currentCycleDay
        
        return calendarDay >= periodStartDay && calendarDay <= periodEndDay
    }
    
    func isFertileDay(day: Int) -> Bool {
        // Check if the given day (1-35) corresponds to a fertile day based on real data
        guard let lastPeriod = periods.last else { return false }
        
        let today = Date()
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: today).day ?? 0
        let currentCycleDay = daysSinceLastPeriod + 1
        
        // Calculate which cycle day this represents in the 35-day calendar
        let cycleStartDay = max(1, currentCycleDay - 17) // Center the current day around day 18
        let calendarDay = day + cycleStartDay - 1
        
        // Fertility window is typically 5 days before ovulation (day 14) and 1 day after
        // So days 9-15 of a typical 28-day cycle
        let fertileStart = averageCycleLength - 19 // 14 (ovulation) - 5 (fertile window) = 9
        let fertileEnd = averageCycleLength - 13   // 14 (ovulation) + 1 = 15
        
        return calendarDay >= fertileStart && calendarDay <= fertileEnd
    }
    
    private func iconForSymptom(_ symptom: String) -> String {
        switch symptom.lowercased() {
        case "cramps": return "bolt.fill"
        case "bloating": return "circle.fill"
        case "fatigue": return "bed.double.fill"
        case "mood swings": return "heart.fill"
        case "headache": return "brain.head.profile"
        case "back pain": return "figure.walk"
        case "breast tenderness": return "heart.circle.fill"
        case "acne": return "face.smiling"
        default: return "exclamationmark.circle.fill"
        }
    }
    
    // Removed loadSampleData() - now using real HealthKit data
    
    private func generateInsights() {
        var newCycleInsights: [String] = []
        var newHealthCorrelations: [String] = []
        
        if periods.isEmpty {
            // No data insights
            newCycleInsights = [
                "Add your first period to get personalized cycle insights",
                "Track your periods to understand your unique cycle patterns",
                "Your insights will appear here once you have enough data"
            ]
            
            newHealthCorrelations = [
                "Period tracking can help identify patterns in your health",
                "Many women notice changes in energy, mood, and sleep during their cycle",
                "Track symptoms to discover your personal health correlations"
            ]
        } else if periods.count < 3 {
            // Limited data insights
            let prediction = predictNextPeriod()
            newCycleInsights = [
                "You've recorded \(periods.count) period\(periods.count == 1 ? "" : "s")",
                "Add more periods to get accurate cycle predictions",
                "Your average cycle length is \(averageCycleLength) days",
                "Your average period duration is \(averagePeriodLength) days",
                "Next period prediction: \(formatDate(prediction.predictedDate)) (confidence: \(prediction.confidenceLevel))"
            ]
            
            newHealthCorrelations = [
                "Continue tracking to discover your unique health patterns",
                "Most women experience cycle-related changes in energy and mood",
                "Your personal correlations will appear as you add more data"
            ]
        } else {
            // Full data insights with enhanced predictions
            let periodPrediction = predictNextPeriod()
            let fertilityPrediction = predictFertilityWindow()
            
            let daysUntilNext = Calendar.current.dateComponents([.day], from: Date(), to: periodPrediction.predictedDate).day ?? 0
            
            // Cycle regularity analysis
            let cycleLengths = zip(periods, periods.dropFirst()).map { period1, period2 in
                Calendar.current.dateComponents([.day], from: period1.startDate, to: period2.startDate).day ?? 28
            }
            
            let cycleVariability = cycleLengths.isEmpty ? 0 : {
                let avg = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
                let variance = cycleLengths.map { pow(Double($0) - avg, 2) }.reduce(0, +) / Double(cycleLengths.count)
                return sqrt(variance)
            }()
            
            let regularityStatus = cycleVariability <= 3 ? "very regular" : 
                                 cycleVariability <= 7 ? "moderately regular" : "irregular"
            
            newCycleInsights = [
                "Your cycle is \(regularityStatus) with an average length of \(String(format: "%.1f", periodPrediction.reasoning.contains("average length of") ? Double(periodPrediction.reasoning.components(separatedBy: "average length of ").last?.components(separatedBy: " days").first ?? "28") ?? 28.0 : Double(averageCycleLength))) days",
                "You typically experience \(averagePeriodLength) days of bleeding",
                daysUntilNext > 0 ? "Your next period is expected in \(daysUntilNext) days (confidence: \(periodPrediction.confidenceLevel))" : "Your period is expected today",
                "You're currently on day \(currentCycleDay) of your cycle"
            ]
            
            // Add enhanced prediction insights
            if periodPrediction.confidenceLevel == "High" {
                newCycleInsights.append("Your prediction confidence is high based on consistent cycle patterns")
            } else if periodPrediction.confidenceLevel == "Medium" {
                newCycleInsights.append("Your prediction confidence is moderate - continue tracking for better accuracy")
            } else {
                newCycleInsights.append("Your prediction confidence is low - more data will improve accuracy")
            }
            
            // Add cycle phase specific insights
            if currentCycleDay <= 5 {
                newCycleInsights.append("You're in the menstrual phase - rest and self-care are important")
            } else if currentCycleDay >= 6 && currentCycleDay <= 14 {
                newCycleInsights.append("You're in the follicular phase - energy and creativity often peak")
            } else if currentCycleDay >= 15 && currentCycleDay <= 17 {
                newCycleInsights.append("You're likely ovulating - fertility is at its highest")
            } else {
                newCycleInsights.append("You're in the luteal phase - progesterone levels are rising")
            }
            
            // Enhanced fertility insights
            if isInFertilityWindow {
                newHealthCorrelations.append("You're currently in your fertile window - the best time for conception")
            } else {
                let daysUntilFertile = Calendar.current.dateComponents([.day], from: Date(), to: fertilityPrediction.fertileStart).day ?? 0
                if daysUntilFertile > 0 {
                    newHealthCorrelations.append("Your next fertile window starts in \(daysUntilFertile) days")
                }
            }
            
            // Health correlations based on symptoms data
            if !symptoms.isEmpty {
                let commonSymptoms = Dictionary(grouping: symptoms) { $0.name }
                    .sorted { $0.value.count > $1.value.count }
                    .prefix(3)
                    .map { $0.key }
                
                if !commonSymptoms.isEmpty {
                    newHealthCorrelations.append("You frequently experience: \(commonSymptoms.joined(separator: ", "))")
                }
                
                // Analyze symptom patterns
                let symptomsByCycleDay = Dictionary(grouping: symptoms) { symptom in
                    guard let lastPeriod = periods.last else { return 0 }
                    let daysSince = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: symptom.date).day ?? 0
                    return daysSince + 1
                }
                
                if let mostSymptomaticDay = symptomsByCycleDay.max(by: { $0.value.count < $1.value.count }) {
                    newHealthCorrelations.append("Day \(mostSymptomaticDay.key) of your cycle tends to have the most symptoms")
                }
            } else {
                newHealthCorrelations.append("Track symptoms to discover your unique health patterns")
                newHealthCorrelations.append("Many women notice changes in energy, mood, and sleep during their cycle")
            }
            
            // Add trend insights
            let trend = calculateCycleTrend()
            if trend.strength > 0.3 {
                newHealthCorrelations.append("Your cycles are \(trend.direction) - this may indicate hormonal changes or lifestyle factors")
            }
        }
        
        cycleInsights = newCycleInsights
        healthCorrelations = newHealthCorrelations
    }
    
    func fetchPeriodsData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch menstrual flow data from HealthKit for the last 6 months
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
            
            // Get menstrual flow samples from HealthKit
            let menstrualFlowSamples = try await healthService.getMenstrualFlowHistory(from: startDate, to: endDate)
            
            // Convert HealthKit samples to PeriodEntry objects
            var newPeriods: [PeriodEntry] = []
            var currentPeriodStart: Date?
            var currentPeriodFlow: FlowIntensity = .medium
            
            for sample in menstrualFlowSamples {
                let flowValue = sample.value
                // If this is a period day (flow > 0)
                if flowValue > 0 {
                    if currentPeriodStart == nil {
                        // Start of a new period
                        currentPeriodStart = sample.startDate
                        currentPeriodFlow = flowIntensityFromHealthKit(flowValue)
                    }
                } else {
                    // End of period
                    if let periodStart = currentPeriodStart {
                        let duration = calendar.dateComponents([.day], from: periodStart, to: sample.startDate).day ?? 1
                        let periodEntry = PeriodEntry(
                            id: UUID().uuidString,
                            startDate: periodStart,
                            duration: duration,
                            flow: currentPeriodFlow
                        )
                        newPeriods.append(periodEntry)
                        currentPeriodStart = nil
                    }
                }
            }
            
            // Handle ongoing period
            if let periodStart = currentPeriodStart {
                let duration = calendar.dateComponents([.day], from: periodStart, to: endDate).day ?? 1
                let periodEntry = PeriodEntry(
                    id: UUID().uuidString,
                    startDate: periodStart,
                    duration: duration,
                    flow: currentPeriodFlow
                )
                newPeriods.append(periodEntry)
            }
            
            // Also fetch from Strapi if available
            if let userId = authRepository.authState.userId {
                do {
                    let strapiResponse = try await strapiRepository.getPeriods(userId: userId)
                    let strapiPeriods = strapiResponse.data
                    
                    // Convert Strapi periods to local format and merge with HealthKit data
                    for strapiPeriod in strapiPeriods {
                        if let startDate = ISO8601DateFormatter().date(from: strapiPeriod.startDate) {
                            let localPeriod = PeriodEntry(
                                id: String(strapiPeriod.id),
                                startDate: startDate,
                                duration: strapiPeriod.duration,
                                flow: flowIntensityFromString(strapiPeriod.flowIntensity)
                            )
                            newPeriods.append(localPeriod)
                        }
                    }
                } catch {
                    print("PeriodsViewModel: Failed to fetch from Strapi: \(error)")
                }
            }
            
            // Update periods on main thread
            await MainActor.run {
                self.periods = newPeriods.sorted { $0.startDate > $1.startDate }
                self.generateInsights()
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch periods data: \(error.localizedDescription)"
            }
            print("PeriodsViewModel: Failed to fetch periods data: \(error)")
        }
    }
    
    func savePeriodData() async {
        guard authRepository.authState.userId != nil else {
            print("PeriodsViewModel: No user ID for saving period data")
            return
        }
        
        do {
            // Save each period to Strapi
            for period in periods {
                let formatter = ISO8601DateFormatter()
                let startDateString = formatter.string(from: period.startDate)
                let endDate = Calendar.current.date(byAdding: .day, value: period.duration - 1, to: period.startDate)
                let endDateString = endDate.map { formatter.string(from: $0) }
                
                _ = try await strapiRepository.syncPeriod(
                    startDate: startDateString,
                    endDate: endDateString,
                    duration: period.duration,
                    flowIntensity: period.flow.rawValue,
                    cycleDay: nil as Int?,
                    cycleLength: nil as Int?,
                    symptoms: nil as [String]?,
                    notes: nil as String?,
                    source: "manual",
                    confidence: nil as Double?,
                    isPrediction: false,
                    predictionAccuracy: nil as Double?,
                    healthKitSampleId: nil as String?,
                    periodId: period.id
                )
            }
            
            print("PeriodsViewModel: Successfully saved \(periods.count) periods to Strapi")
            
        } catch {
            print("PeriodsViewModel: Failed to save period data: \(error)")
        }
    }
    
    private func flowIntensityFromHealthKit(_ flowValue: Int) -> FlowIntensity {
        switch flowValue {
        case 1: return .light
        case 2: return .medium
        case 3: return .heavy
        default: return .medium
        }
    }
    
    private func flowIntensityFromString(_ intensity: String) -> FlowIntensity {
        switch intensity.lowercased() {
        case "light": return .light
        case "medium": return .medium
        case "heavy": return .heavy
        default: return .medium
        }
    }
    
    // MARK: - Enhanced Statistical Predictions
    
    struct PeriodPrediction {
        let predictedDate: Date
        let confidence: Double // 0.0 to 1.0
        let confidenceLevel: String // "High", "Medium", "Low"
        let reasoning: String
        let range: ClosedRange<Date> // Confidence interval
    }
    
    struct FertilityPrediction {
        let fertileStart: Date
        let fertileEnd: Date
        let ovulationDate: Date
        let confidence: Double
        let reasoning: String
    }
    
    // Enhanced period prediction with weighted analysis
    func predictNextPeriod() -> PeriodPrediction {
        guard periods.count >= 2 else {
            return PeriodPrediction(
                predictedDate: Calendar.current.date(byAdding: .day, value: 28, to: Date()) ?? Date(),
                confidence: 0.3,
                confidenceLevel: "Low",
                reasoning: "Insufficient data for accurate prediction",
                range: Calendar.current.date(byAdding: .day, value: 25, to: Date())!...Calendar.current.date(byAdding: .day, value: 31, to: Date())!
            )
        }
        
        // Calculate cycle lengths with weights (recent cycles weighted more heavily)
        let cycleLengths = calculateWeightedCycleLengths()
        
        // Calculate trend (are cycles getting longer/shorter?)
        let trend = calculateCycleTrend()
        
        // Calculate variability
        let variability = calculateCycleVariability()
        
        // Predict next period date
        let basePrediction = Calendar.current.date(byAdding: .day, value: Int(cycleLengths.weightedAverage), to: lastPeriodStart) ?? Date()
        
        // Adjust for trend
        let trendAdjustedDate = Calendar.current.date(byAdding: .day, value: Int(trend.adjustment), to: basePrediction) ?? basePrediction
        
        // Calculate confidence based on data quality
        let confidence = calculatePredictionConfidence(cycleCount: periods.count, variability: variability)
        
        // Calculate confidence interval
        let range = calculateConfidenceInterval(predictedDate: trendAdjustedDate, variability: variability)
        
        // Generate reasoning
        let reasoning = generatePredictionReasoning(
            cycleCount: periods.count,
            averageLength: cycleLengths.weightedAverage,
            trend: trend,
            variability: variability
        )
        
        return PeriodPrediction(
            predictedDate: trendAdjustedDate,
            confidence: confidence,
            confidenceLevel: confidenceLevel(for: confidence),
            reasoning: reasoning,
            range: range
        )
    }
    
    // Enhanced fertility prediction
    func predictFertilityWindow() -> FertilityPrediction {
        let periodPrediction = predictNextPeriod()
        
        // Fertility window is typically 5 days before ovulation (day 14) and 1 day after
        // So days 9-15 of a typical cycle
        let ovulationDay = 14 // Standard ovulation day
        let fertileStartDay = ovulationDay - 5 // 5 days before ovulation
        let fertileEndDay = ovulationDay + 1 // 1 day after ovulation
        
        // Calculate ovulation date based on predicted period
        let daysUntilPeriod = Calendar.current.dateComponents([.day], from: Date(), to: periodPrediction.predictedDate).day ?? 0
        let ovulationDate = Calendar.current.date(byAdding: .day, value: -(daysUntilPeriod - ovulationDay), to: periodPrediction.predictedDate) ?? Date()
        
        let fertileStart = Calendar.current.date(byAdding: .day, value: fertileStartDay, to: ovulationDate) ?? Date()
        let fertileEnd = Calendar.current.date(byAdding: .day, value: fertileEndDay, to: ovulationDate) ?? Date()
        
        let reasoning = "Based on your cycle pattern, ovulation is predicted around \(formatDate(ovulationDate)). Your fertile window is typically 6 days."
        
        return FertilityPrediction(
            fertileStart: fertileStart,
            fertileEnd: fertileEnd,
            ovulationDate: ovulationDate,
            confidence: periodPrediction.confidence * 0.8, // Fertility predictions are less certain
            reasoning: reasoning
        )
    }
    
    // MARK: - Helper Methods for Enhanced Predictions
    
    private struct WeightedCycleLengths {
        let weightedAverage: Double
        let recentAverage: Double
        let overallAverage: Double
    }
    
    private struct CycleTrend {
        let direction: String // "increasing", "decreasing", "stable"
        let adjustment: Double // days to adjust prediction
        let strength: Double // 0.0 to 1.0
    }
    
    private func calculateWeightedCycleLengths() -> WeightedCycleLengths {
        guard periods.count >= 2 else {
            return WeightedCycleLengths(weightedAverage: 28.0, recentAverage: 28.0, overallAverage: 28.0)
        }
        
        let cycleLengths = zip(periods, periods.dropFirst()).map { period1, period2 in
            Calendar.current.dateComponents([.day], from: period1.startDate, to: period2.startDate).day ?? 28
        }
        
        let overallAverage = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
        
        // Weight recent cycles more heavily (exponential decay)
        var weightedSum = 0.0
        var weightSum = 0.0
        
        for (index, length) in cycleLengths.enumerated() {
            let weight = pow(0.8, Double(cycleLengths.count - 1 - index)) // More recent = higher weight
            weightedSum += Double(length) * weight
            weightSum += weight
        }
        
        let weightedAverage = weightedSum / weightSum
        
        // Recent average (last 3 cycles)
        let recentCycles = Array(cycleLengths.suffix(3))
        let recentAverage = Double(recentCycles.reduce(0, +)) / Double(recentCycles.count)
        
        return WeightedCycleLengths(
            weightedAverage: weightedAverage,
            recentAverage: recentAverage,
            overallAverage: overallAverage
        )
    }
    
    private func calculateCycleTrend() -> CycleTrend {
        guard periods.count >= 4 else {
            return CycleTrend(direction: "stable", adjustment: 0.0, strength: 0.0)
        }
        
        let cycleLengths = zip(periods, periods.dropFirst()).map { period1, period2 in
            Calendar.current.dateComponents([.day], from: period1.startDate, to: period2.startDate).day ?? 28
        }
        
        // Split into two halves to compare
        let midPoint = cycleLengths.count / 2
        let earlierCycles = Array(cycleLengths.prefix(midPoint))
        let laterCycles = Array(cycleLengths.suffix(cycleLengths.count - midPoint))
        
        let earlierAverage = Double(earlierCycles.reduce(0, +)) / Double(earlierCycles.count)
        let laterAverage = Double(laterCycles.reduce(0, +)) / Double(laterCycles.count)
        
        let difference = laterAverage - earlierAverage
        let strength = min(abs(difference) / 5.0, 1.0) // Normalize to 0-1
        
        let direction: String
        let adjustment: Double
        
        if abs(difference) < 1.0 {
            direction = "stable"
            adjustment = 0.0
        } else if difference > 0 {
            direction = "increasing"
            adjustment = difference * 0.5 // Conservative adjustment
        } else {
            direction = "decreasing"
            adjustment = difference * 0.5 // Conservative adjustment
        }
        
        return CycleTrend(direction: direction, adjustment: adjustment, strength: strength)
    }
    
    private func calculateCycleVariability() -> Double {
        guard periods.count >= 2 else { return 0.0 }
        
        let cycleLengths = zip(periods, periods.dropFirst()).map { period1, period2 in
            Calendar.current.dateComponents([.day], from: period1.startDate, to: period2.startDate).day ?? 28
        }
        
        let average = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
        let variance = cycleLengths.map { pow(Double($0) - average, 2) }.reduce(0, +) / Double(cycleLengths.count)
        return sqrt(variance)
    }
    
    private func calculatePredictionConfidence(cycleCount: Int, variability: Double) -> Double {
        // Base confidence on number of cycles
        var confidence = min(Double(cycleCount) / 6.0, 1.0) // Max confidence at 6+ cycles
        
        // Reduce confidence based on variability
        let variabilityPenalty = min(variability / 7.0, 0.3) // Max 30% penalty for high variability
        confidence -= variabilityPenalty
        
        // Ensure confidence is between 0.1 and 1.0
        return max(0.1, min(confidence, 1.0))
    }
    
    private func calculateConfidenceInterval(predictedDate: Date, variability: Double) -> ClosedRange<Date> {
        let intervalDays = max(3.0, variability * 1.5) // At least 3 days, scales with variability
        
        let startDate = Calendar.current.date(byAdding: .day, value: -Int(intervalDays), to: predictedDate) ?? predictedDate
        let endDate = Calendar.current.date(byAdding: .day, value: Int(intervalDays), to: predictedDate) ?? predictedDate
        
        return startDate...endDate
    }
    
    private func confidenceLevel(for confidence: Double) -> String {
        switch confidence {
        case 0.7...1.0: return "High"
        case 0.4..<0.7: return "Medium"
        default: return "Low"
        }
    }
    
    private func generatePredictionReasoning(cycleCount: Int, averageLength: Double, trend: CycleTrend, variability: Double) -> String {
        var reasoning = "Based on your \(cycleCount) recorded cycle\(cycleCount == 1 ? "" : "s")"
        
        reasoning += " with an average length of \(String(format: "%.1f", averageLength)) days"
        
        if trend.strength > 0.3 {
            reasoning += ". Your cycles are \(trend.direction), suggesting a \(trend.direction) trend"
        }
        
        if variability > 5.0 {
            reasoning += ". Your cycle variability is \(variability > 8.0 ? "high" : "moderate"), which may affect prediction accuracy"
        } else {
            reasoning += ". Your cycles are quite regular"
        }
        
        return reasoning
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - UI Data Models

// UI-specific data models that extend the API models
struct PeriodEntry: Identifiable, Codable {
    let id: String
    let startDate: Date
    let duration: Int
    let flow: FlowIntensity
    
    init(from strapiEntry: StrapiPeriodEntry) {
        self.id = String(strapiEntry.id)
        self.startDate = ISO8601DateFormatter().date(from: strapiEntry.startDate) ?? Date()
        self.duration = strapiEntry.duration
        self.flow = FlowIntensity(rawValue: strapiEntry.flowIntensity) ?? .medium
    }
    
    init(id: String, startDate: Date, duration: Int, flow: FlowIntensity) {
        self.id = id
        self.startDate = startDate
        self.duration = duration
        self.flow = flow
    }
}

enum FlowIntensity: String, CaseIterable, Codable {
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"
    
    var color: Color {
        switch self {
        case .light: return .pink.opacity(0.3)
        case .medium: return .pink.opacity(0.6)
        case .heavy: return .pink
        }
    }
}

struct SymptomEntry: Identifiable, Codable {
    let id: String
    let name: String
    let severity: SymptomSeverity
    let date: Date
    let icon: String
    
    init(from strapiEntry: PeriodSymptomEntry) {
        self.id = String(strapiEntry.id)
        self.name = strapiEntry.name
        self.severity = SymptomSeverity(rawValue: strapiEntry.severity) ?? .mild
        self.date = ISO8601DateFormatter().date(from: strapiEntry.date) ?? Date()
        self.icon = strapiEntry.icon ?? "exclamationmark.circle.fill"
    }
    
    init(id: String, name: String, severity: SymptomSeverity, date: Date, icon: String) {
        self.id = id
        self.name = name
        self.severity = severity
        self.date = date
        self.icon = icon
    }
}

enum SymptomSeverity: String, CaseIterable, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    
    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct SymptomHistoryEntry: Identifiable {
    let id: String
    let date: Date
    let symptoms: [String]
} 