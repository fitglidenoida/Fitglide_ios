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
    @Published var periods: [LocalPeriodEntry] = []
    @Published var symptoms: [SymptomEntry] = []
    @Published var cycleInsights: [String] = []
    @Published var healthCorrelations: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Settings
    @Published var periodReminders = true
    @Published var fertilityAlerts = true
    @Published var symptomReminders = true
    
    // Computed properties
    var lastPeriodStart: Date {
        return periods.last?.startDate ?? Date()
    }
    
    var nextPeriodDate: Date {
        return Calendar.current.date(byAdding: .day, value: averageCycleLength, to: lastPeriodStart) ?? Date()
    }
    
    var currentCycleDay: Int {
        guard let lastPeriod = periods.last else { return 1 }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: Date()).day ?? 0
        return daysSinceLastPeriod + 1
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
        let fertileStart = Calendar.current.date(byAdding: .day, value: averageCycleLength - 14, to: lastPeriodStart) ?? Date()
        let fertileEnd = Calendar.current.date(byAdding: .day, value: averageCycleLength - 10, to: lastPeriodStart) ?? Date()
        let today = Date()
        return today >= fertileStart && today <= fertileEnd
    }
    
    var nextFertilityWindow: Date {
        return Calendar.current.date(byAdding: .day, value: averageCycleLength - 14, to: lastPeriodStart) ?? Date()
    }
    
    var recentPeriods: [LocalPeriodEntry] {
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
    
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        
        // Load real data instead of sample data
        Task {
            await loadPeriodsData()
        }
    }
    
    func addPeriod(startDate: Date, duration: Int, flow: FlowIntensity) {
        let newPeriod = LocalPeriodEntry(
            id: UUID().uuidString,
            startDate: startDate,
            duration: duration,
            flow: flow
        )
        periods.append(newPeriod)
        generateInsights()
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
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: Date()).day ?? 0
        let currentCycleDay = daysSinceLastPeriod + 1
        let periodStartDay = currentCycleDay - lastPeriod.duration
        return day >= periodStartDay && day <= currentCycleDay
    }
    
    func isFertileDay(day: Int) -> Bool {
        // Check if the given day (1-35) corresponds to a fertile day based on real data
        let fertileStart = averageCycleLength - 14
        let fertileEnd = averageCycleLength - 10
        return day >= fertileStart && day <= fertileEnd
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
        cycleInsights = [
            "Your cycle is regular with an average length of \(averageCycleLength) days",
            "You typically experience \(averagePeriodLength) days of bleeding",
            "Your next period is expected in \(Calendar.current.dateComponents([.day], from: Date(), to: nextPeriodDate).day ?? 0) days",
            "You're currently on day \(currentCycleDay) of your cycle"
        ]
        
        healthCorrelations = [
            "You tend to have more energy during ovulation (days 12-16)",
            "Your sleep quality improves after day 5 of your period",
            "You're more likely to crave sweets during the luteal phase",
            "Your workout performance peaks during the follicular phase"
        ]
    }
    
    @MainActor
    func loadPeriodsData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var newPeriods: [LocalPeriodEntry] = []
            
            // Fetch from HealthKit for the last 6 months
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
            
            let healthKitPeriods = try await healthService.getMenstrualFlowHistory(from: startDate, to: endDate)
            for period in healthKitPeriods {
                let duration = Calendar.current.dateComponents([.day], from: period.startDate, to: period.endDate).day ?? 1
                let localPeriod = LocalPeriodEntry(
                    id: UUID().uuidString,
                    startDate: period.startDate,
                    duration: duration,
                    flow: flowIntensityFromHealthKit(period.value)
                )
                newPeriods.append(localPeriod)
            }
            
            // Fetch from Strapi if user is logged in
            if let userId = authRepository.authState.userId {
                do {
                    let strapiResponse = try await strapiRepository.getPeriods(userId: userId)
                    let strapiPeriods = strapiResponse.data
                    
                    // Convert Strapi periods to local format and merge with HealthKit data
                    for strapiPeriod in strapiPeriods {
                        let localPeriod = LocalPeriodEntry(from: strapiPeriod)
                        newPeriods.append(localPeriod)
                    }
                } catch {
                    print("PeriodsViewModel: Failed to fetch from Strapi: \(error)")
                }
            }
            
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
        
        // Save each period to Strapi
        for period in periods {
            let formatter = ISO8601DateFormatter()
            let startDateString = formatter.string(from: period.startDate)
            let endDate = Calendar.current.date(byAdding: .day, value: period.duration - 1, to: period.startDate)
            let endDateString = endDate.map { formatter.string(from: $0) }
            
            // API call to save period data will be implemented in future updates
            print("PeriodsViewModel: Would save period: \(startDateString) to \(endDateString ?? "ongoing")")
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
    
    private func flowIntensityFromString(_ flowString: String) -> FlowIntensity {
        switch flowString.lowercased() {
        case "light": return .light
        case "medium": return .medium
        case "heavy": return .heavy
        default: return .medium
        }
    }
    
    func predictFertilityWindow() -> FertilityPrediction {
        let fertileStart = Calendar.current.date(byAdding: .day, value: averageCycleLength - 14, to: lastPeriodStart) ?? Date()
        let fertileEnd = Calendar.current.date(byAdding: .day, value: averageCycleLength - 10, to: lastPeriodStart) ?? Date()
        
        // Calculate confidence based on cycle regularity
        let confidence = periods.count >= 3 ? 0.85 : 0.6
        
        return FertilityPrediction(
            fertileStart: fertileStart,
            fertileEnd: fertileEnd,
            confidence: confidence
        )
    }
}

// MARK: - Data Models

// Local model for UI that works with API model
struct LocalPeriodEntry: Identifiable, Codable {
    let id: String
    let startDate: Date
    let duration: Int
    let flow: FlowIntensity
    
    // Convert from API model
    init(from apiEntry: PeriodEntry) {
        self.id = String(apiEntry.id)
        self.startDate = ISO8601DateFormatter().date(from: apiEntry.startDate) ?? Date()
        self.duration = apiEntry.duration
        self.flow = FlowIntensity(rawValue: apiEntry.flowIntensity) ?? .medium
    }
    
    // Create for local use
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

struct FertilityPrediction {
    let fertileStart: Date
    let fertileEnd: Date
    let confidence: Double
} 