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
        guard let lastPeriod = periods.last else { return Date() }
        return Calendar.current.date(byAdding: .day, value: averageCycleLength, to: lastPeriod.startDate) ?? Date()
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
            
            // Update periods on main thread
            await MainActor.run {
                self.periods = newPeriods.sorted { $0.startDate > $1.startDate }
                self.generateInsights()
            }
            
            // Also fetch from Strapi if available
            let _ = authRepository.authState.userId ?? ""
            // TODO: Implement API calls for periods data from Strapi
            // This would sync with the backend
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch periods data: \(error.localizedDescription)"
            }
            print("PeriodsViewModel: Failed to fetch periods data: \(error)")
        }
    }
    
    func savePeriodData() async {
        let userId = authRepository.authState.userId ?? ""
        // TODO: Implement API calls to save periods data
        print("PeriodsViewModel: Would save data for user: \(userId)")
    }
    
    private func flowIntensityFromHealthKit(_ flowValue: Int) -> FlowIntensity {
        switch flowValue {
        case 1: return .light
        case 2: return .medium
        case 3: return .heavy
        default: return .medium
        }
    }
}

// MARK: - Data Models

struct PeriodEntry: Identifiable, Codable {
    let id: String
    let startDate: Date
    let duration: Int
    let flow: FlowIntensity
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