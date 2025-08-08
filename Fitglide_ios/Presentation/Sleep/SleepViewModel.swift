//
//  SleepViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 14/06/25.
//

import Combine
import Foundation
import HealthKit
import UserNotifications
import os.log

// Data Structures (moved to file scope)
struct SleepDataUi {
    let score: Float
    let debt: String
    let injuryRisk: Float
    let bedtime: String
    let alarm: String
    let stages: [SleepStage]
    let insights: [String]
    let streak: Int
    let challengeActive: Bool
    let restTime: Float
    let actualSleepTime: Float
    let scoreLegend: SleepScoreLegend
}

struct SleepStage {
    let duration: Int
    let type: String
}

struct SleepScoreLegend {
    let overallScoreDescription: String
    let scoreRanges: [String]
    let deepSleepContribution: String
    let remSleepContribution: String
    let awakeTimeImpact: String
    let consistencyImpact: String
}

// Logger Extension
extension Logger {
    static let sleep = Logger(subsystem: "com.fitglide", category: "SleepViewModel")
}

class SleepViewModel: ObservableObject {
    @Published var sleepData: SleepDataUi?
    @Published var syncEnabled: Bool
    @Published var sleepGoal: Float
    @Published var selectedSound: String = "Rain"
    @Published var firstname: String? // Added firstname property
    @Published var isLoading: Bool = false
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()
    private var fetchTask: Task<Void, Never>?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private let debugDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init(
        healthService: HealthService,
        strapiRepository: StrapiRepository,
        authRepository: AuthRepository
    ) async {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository

        // Load settings from UserDefaults
        self.syncEnabled = UserDefaults.standard.bool(forKey: "sleepSyncEnabled")
        self.sleepGoal = UserDefaults.standard.float(forKey: "sleepGoal") > 0 ?
            UserDefaults.standard.float(forKey: "sleepGoal") : 8.0

        // Asynchronously initialize firstname
        await self.initializeFirstname()

        // Request HealthKit and notification authorization
        await requestHealthKitAuthorization()
        requestNotificationAuthorization()

        // Fetch initial sleep data
        await fetchSleepData(for: Date())
    }

    @MainActor
    convenience init(
        strapiRepository: StrapiRepository,
        authRepository: AuthRepository
    ) async {
        await self.init(
            healthService: HealthService(),
            strapiRepository: strapiRepository,
            authRepository: authRepository
        )
    }

    private func requestHealthKitAuthorization() async {
        do {
            try await healthService.requestAuthorization()
            Logger.sleep.info("HealthKit authorization requested")
        } catch {
            Logger.sleep.error("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                Logger.sleep.info("Notification authorization granted")
            } else if let error = error {
                Logger.sleep.error("Notification authorization failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func fetchSleepData(for date: Date) async {
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            await MainActor.run {
                isLoading = true
            }
            
            let dateStr = dateFormatter.string(from: date)
            let debugDateStr = debugDateFormatter.string(from: date)
            Logger.sleep.debug("Fetching sleep data for \(dateStr) (date: \(debugDateStr))")
            var fetchedLog: SleepLogEntry?

        do {
            let response = try await strapiRepository.fetchSleepLog(date: date)
            Logger.sleep.debug("Fetched \(response.data.count) logs from Strapi")

            // ✅ Case 1: Use if valid sleepDuration
            if let existingLog = response.data.first(where: { $0.sleepDuration > 0 }) {
                Logger.sleep.debug("Valid sleep log found in Strapi for \(dateStr)")
                fetchedLog = existingLog
            } else {
                // ❌ Case 2: Log is missing or has zero duration → fallback to HealthKit
                Logger.sleep.debug("No valid sleep duration in Strapi. Checking HealthKit...")
                let healthKitData = try await healthService.getSleep(date: date)

                if healthKitData.total > 0 || healthKitData.light > 0 || healthKitData.deep > 0 || healthKitData.rem > 0 || healthKitData.awake > 0 {
                    let syncResult = await strapiRepository.syncSleepLog(date: date, sleepData: healthKitData)

                    switch syncResult {
                    case .success(let response):
                        Logger.sleep.info("Successfully synced sleep data to Strapi for \(dateStr)")
                        fetchedLog = response.data
                    case .failure(let error):
                        Logger.sleep.error("Failed to sync sleep data to Strapi: \(error.localizedDescription)")
                    }
                } else {
                    Logger.sleep.warning("No valid HealthKit sleep data for \(dateStr)")
                }
            }
        } catch {
            Logger.sleep.error("Failed to fetch from Strapi: \(error.localizedDescription)")
        }

        guard let finalLog = fetchedLog else {
            Logger.sleep.debug("No valid sleep log available after all checks")
            await MainActor.run {
                self.sleepData = SleepDataUi(
                    score: 0,
                    debt: "0h0m",
                    injuryRisk: 0,
                    bedtime: "N/A",
                    alarm: "N/A",
                    stages: [],
                    insights: ["No sleep data found"],
                    streak: 0,
                    challengeActive: false,
                    restTime: sleepGoal,
                    actualSleepTime: 0,
                    scoreLegend: SleepScoreLegend(
                        overallScoreDescription: "Poor: No sleep data",
                        scoreRanges: ["90-100: Excellent", "70-89: Good", "50-69: Fair", "0-49: Poor"],
                        deepSleepContribution: "0% of score: No deep sleep data",
                        remSleepContribution: "0% of score: No REM sleep data",
                        awakeTimeImpact: "No penalty: No awake time data",
                        consistencyImpact: "0% of score: No consistency data"
                    )
                )
                self.isLoading = false
            }
            return
        }

        guard let converted = convertStrapiLogToSleepData(finalLog) else {
            Logger.sleep.warning("Conversion failed for Strapi log at \(dateStr)")
            await MainActor.run {
                isLoading = false
            }
            return
        }

        // Process UI update in background to avoid blocking
        await processAndUpdateUI(strapiLog: finalLog, convertedData: converted, for: date)
        await MainActor.run {
            isLoading = false
        }
        }
    }
    
    @MainActor
    func fetchAndSyncWeeklySleepData() async {
        Logger.sleep.info("Starting weekly sleep data fetch and sync...")
        
        let calendar = Calendar.current
        let today = Date()
        
        // Loop through the past 7 days
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let dateStr = dateFormatter.string(from: date)
            
            Logger.sleep.info("Checking day \(dayOffset + 1): \(dateStr)")
            
            do {
                // First check if we already have this data in Strapi
                let strapiResponse = try await strapiRepository.fetchSleepLog(date: date)
                
                if strapiResponse.data.first(where: { $0.sleepDuration > 0 }) != nil {
                    Logger.sleep.info("Day \(dayOffset + 1): Found existing data in Strapi for \(dateStr)")
                } else {
                    // No data in Strapi, check HealthKit
                    Logger.sleep.info("Day \(dayOffset + 1): No data in Strapi, checking HealthKit for \(dateStr)")
                    let healthKitData = try await healthService.getSleep(date: date)
                    
                    if healthKitData.total > 0 || healthKitData.light > 0 || healthKitData.deep > 0 || healthKitData.rem > 0 || healthKitData.awake > 0 {
                        Logger.sleep.info("Day \(dayOffset + 1): Found HealthKit data for \(dateStr) - Total: \(healthKitData.total/3600)h, Light: \(healthKitData.light/3600)h, Deep: \(healthKitData.deep/3600)h, REM: \(healthKitData.rem/3600)h")
                        
                        let syncResult = await strapiRepository.syncSleepLog(date: date, sleepData: healthKitData)
                        switch syncResult {
                        case .success(let response):
                            Logger.sleep.info("Day \(dayOffset + 1): Successfully synced to Strapi for \(dateStr) - ID: \(response.data.documentId)")
                        case .failure(let error):
                            Logger.sleep.error("Day \(dayOffset + 1): Failed to sync to Strapi for \(dateStr): \(error.localizedDescription)")
                        }
                    } else {
                        Logger.sleep.info("Day \(dayOffset + 1): No HealthKit data for \(dateStr)")
                    }
                }
            } catch {
                Logger.sleep.error("Day \(dayOffset + 1): Error processing \(dateStr): \(error.localizedDescription)")
            }
        }
        
        Logger.sleep.info("Weekly sleep data fetch and sync completed")
    }

    @MainActor
    func syncSleepData(for date: Date, sleepData: HealthService.SleepData) async -> Result<Void, Error> {
        let dateStr = dateFormatter.string(from: date)
        Logger.sleep.debug("Syncing sleep data for \(dateStr)")

        if sleepData.total <= 0 && sleepData.light <= 0 && sleepData.deep <= 0 && sleepData.rem <= 0 && sleepData.awake <= 0 {
            Logger.sleep.warning("Skipping sync: All durations are zero")
            return .success(())
        }

        let result = await strapiRepository.syncSleepLog(date: date, sleepData: sleepData)
        switch result {
        case .success(let response):
            Logger.sleep.info("Synced sleep log ID: \(response.data.documentId)")
            return .success(())
        case .failure(let error):
            Logger.sleep.error("Sync failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    @MainActor
    func manualSync(for date: Date) async {
        do {
            let sleepData = try await healthService.getSleep(date: date)
            let result = await syncSleepData(for: date, sleepData: sleepData)
            switch result {
            case .success:
                Logger.sleep.info("Manual sync completed successfully for \(self.dateFormatter.string(from: date))")
            case .failure(let error):
                Logger.sleep.error("Manual sync failed: \(error.localizedDescription)")
            }
        } catch {
            Logger.sleep.error("Failed to fetch sleep data for manual sync: \(error.localizedDescription)")
        }
    }

    private func processAndUpdateUI(
        strapiLog: SleepLogEntry,
        convertedData: HealthService.SleepData,
        for date: Date
    ) async {
        // ---- Part 1: Raw values from Strapi ----
        guard let startTime = strapiLog.startTime, let endTime = strapiLog.endTime else {
            Logger.sleep.warning("Missing start or end time in Strapi log")
            return
        }

        let actualSleepTime = Float(strapiLog.sleepDuration)
        let bedtime = startTime
        let alarmTime = endTime
        let stages = [
            SleepStage(duration: Int(strapiLog.lightSleepDuration * 60), type: "Light"),
            SleepStage(duration: Int(strapiLog.deepSleepDuration * 60), type: "Deep"),
            SleepStage(duration: Int(strapiLog.remSleepDuration * 60), type: "REM")
        ]

        // ---- Part 2: Calculated insights based on converted data ----
        let workoutIntensity = (try? await healthService.getCaloriesBurned(date: date)) ?? 0
        let recommendedSleepHours = await calculateRecommendedSleep(date: date, workoutIntensity: Double(workoutIntensity)) ?? sleepGoal

        let debtMinutes = max(Int((recommendedSleepHours * 60) - (actualSleepTime * 60)), 0)
        let debt = formatDebt(debtMinutes)

        let insights = generateInsights(sleepData: convertedData, debtMinutes: debtMinutes)

        let (score, legend) = await calculateComprehensiveSleepScore(
            sleepData: convertedData,
            targetHours: recommendedSleepHours,
            date: date
        )

        let streak = await calculateStreak(date: date)

        // ---- Update UI ----
        await MainActor.run {
            self.sleepData = SleepDataUi(
                score: score,
                debt: debt,
                injuryRisk: debtMinutes > 120 ? 25 : 0,
                bedtime: dateFormatter.string(from: bedtime).uppercased(),
                alarm: dateFormatter.string(from: alarmTime).uppercased(),
                stages: stages,
                insights: insights,
                streak: streak,
                challengeActive: debtMinutes <= 0,
                restTime: recommendedSleepHours,
                actualSleepTime: actualSleepTime,
                scoreLegend: legend
            )

            Logger.sleep.debug("Sleep UI updated: \(actualSleepTime)h sleep, \(debt) debt, score \(score)")
        }
    }

    func updateSettings(syncEnabled: Bool, sleepGoal: Float, selectedSound: String) async {
        await MainActor.run {
            self.syncEnabled = syncEnabled
            self.sleepGoal = sleepGoal
            self.selectedSound = selectedSound

            UserDefaults.standard.set(syncEnabled, forKey: "sleepSyncEnabled")
            UserDefaults.standard.set(sleepGoal, forKey: "sleepGoal")
            UserDefaults.standard.set(selectedSound, forKey: "sleepSound")
        }

        if syncEnabled {
            let alarmTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date().addingTimeInterval(24 * 3600))!
            if await setAlarm(alarmTime: alarmTime) {
                Logger.sleep.debug("Alarm synced successfully for \(self.dateFormatter.string(from: alarmTime))")
            } else {
                Logger.sleep.warning("Failed to sync alarm, permission may be missing")
            }
            await fetchSleepData(for: Date()) // Refresh data after settings update
            do {
                let sleepData = try await healthService.getSleep(date: Date())
                let syncResult = await syncSleepData(for: Date(), sleepData: sleepData)
                switch syncResult {
                case .success:
                    Logger.sleep.info("Synced sleep data after enabling sync")
                case .failure(let error):
                    Logger.sleep.error("Failed to sync sleep data after enabling sync: \(error.localizedDescription)")
                }
            } catch {
                Logger.sleep.error("Failed to fetch sleep data for sync: \(error.localizedDescription)")
            }
        }
    }

    private func convertStrapiLogToSleepData(_ log: SleepLogEntry) -> HealthService.SleepData? {
        guard let startTime = log.startTime, let endTime = log.endTime else {
            Logger.sleep.warning("Missing startTime or endTime in Strapi log: \(log.documentId)")
            return nil
        }

        _ = ISO8601DateFormatter()
        let start = startTime
        let end = endTime
        
        return HealthService.SleepData(
            total: TimeInterval(log.sleepDuration * 3600), // Convert hours to seconds
            deep: TimeInterval(log.deepSleepDuration * 3600),
            rem: TimeInterval(log.remSleepDuration * 3600),
            light: TimeInterval(log.lightSleepDuration * 3600),
            awake: TimeInterval(log.sleepAwakeDuration * 3600),
            start: start,
            end: end
        )
    }

    private func calculateRecommendedSleep(date: Date, workoutIntensity: Double) async -> Float? {
        guard let userId = authRepository.authState.userId, let _ = authRepository.authState.jwt else {
            Logger.sleep.warning("Missing userId or token")
            return nil
        }

        var dobString: String?
        for attempt in 0..<3 {
            do {
                let response = try await strapiRepository.getHealthVitals(userId: userId)
                if let fetchedDob = response.data.first?.date_of_birth {
                    dobString = fetchedDob
                    Logger.sleep.debug("Fetched date of birth (attempt \(attempt + 1)): \(fetchedDob)")
                    break
                }
            } catch {
                Logger.sleep.error("Failed to fetch health vitals (attempt \(attempt + 1)): \(error.localizedDescription)")
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }

        guard let dobString = dobString,
              let dob = isoFormatter.date(from: dobString) else {
            Logger.sleep.warning("Invalid or missing date of birth after retries")
            return nil
        }

        let age = Calendar.current.dateComponents([.year], from: dob, to: date).year ?? 30
        Logger.sleep.debug("Calculated age: \(age)")
        let baseSleep: Float = age < 18 ? 9 : age <= 64 ? 8 : 7.5

        let workoutAdjustment: Float
        do {
            let response = try await strapiRepository.getWorkoutLogs(userId: userId, date: dateFormatter.string(from: date))
            workoutAdjustment = !response.data.isEmpty ? (workoutIntensity > 1000 ? 1 : workoutIntensity > 500 ? 0.5 : 0) : 0
            Logger.sleep.debug("Workout adjustment: \(workoutAdjustment) based on intensity \(workoutIntensity)")
        } catch {
            workoutAdjustment = 0
            Logger.sleep.error("Failed to fetch workout logs: \(error.localizedDescription)")
        }

        let recommendedSleep = baseSleep + workoutAdjustment
        Logger.sleep.debug("Recommended sleep calculated: \(recommendedSleep) hours")
        return recommendedSleep
    }

    private func calculateComprehensiveSleepScore(
        sleepData: HealthService.SleepData,
        targetHours: Float,
        date: Date
    ) async -> (Float, SleepScoreLegend) {
        let effectiveTotal = max(sleepData.total, sleepData.light + sleepData.deep + sleepData.rem)
        guard effectiveTotal > 0 else {
            return (0, SleepScoreLegend(
                overallScoreDescription: "Poor: Invalid sleep data",
                scoreRanges: ["90-100: Excellent", "70-89: Good", "50-69: Fair", "0-49: Poor"],
                deepSleepContribution: "0% of score: No deep sleep data",
                remSleepContribution: "0% of score: No REM sleep data",
                awakeTimeImpact: "No penalty: No awake time data",
                consistencyImpact: "0% of score: No consistency data"
            ))
        }

        let totalSleepHours = Float(effectiveTotal / 3600)
        let baseScore = min((totalSleepHours / targetHours) * 50, 50)

        let deepPercentage = Float(sleepData.deep / effectiveTotal) * 100
        let deepScore: Float = deepPercentage >= 20 ? 20 : deepPercentage >= 15 ? 15 : 10

        let remPercentage = Float(sleepData.rem / effectiveTotal) * 100
        let remScore: Float = remPercentage >= 20 ? 15 : remPercentage >= 15 ? 10 : 5

        let awakePercentage = Float(sleepData.awake / effectiveTotal) * 100
        let awakePenalty: Float = awakePercentage <= 10 ? 0 : awakePercentage <= 20 ? -5 : -10

        let consistencyScore = await calculateConsistencyScore(date: date)

        let totalScore = max(min(baseScore + deepScore + remScore + consistencyScore + awakePenalty, 100), 0)

        let overallDescription = totalScore >= 90 ? "Excellent: High deep sleep and consistency" :
                                totalScore >= 70 ? "Good: Balanced sleep with minor disruptions" :
                                totalScore >= 50 ? "Fair: Adequate sleep but needs improvement" :
                                "Poor: Insufficient sleep quality or duration"

        let legend = SleepScoreLegend(
            overallScoreDescription: overallDescription,
            scoreRanges: ["90-100: Excellent", "70-89: Good", "50-69: Fair", "0-49: Poor"],
            deepSleepContribution: "\(Int(deepScore / 20 * 100))% of score: \(deepPercentage >= 20 ? "Adequate" : "Needs more") deep sleep",
            remSleepContribution: "\(Int(remScore / 15 * 100))% of score: \(remPercentage >= 20 ? "Adequate" : "Needs more") REM sleep",
            awakeTimeImpact: "\(awakePenalty == 0 ? "No penalty" : "Penalty applied"): \(Int(awakePercentage))% awake time",
            consistencyImpact: "\(Int(consistencyScore / 15 * 100))% of score: \(consistencyScore >= 10 ? "Consistent" : "Variable") bedtime"
        )

        Logger.sleep.debug("Calculated sleep score: totalScore=\(totalScore), baseScore=\(baseScore), deepScore=\(deepScore), remScore=\(remScore), awakePenalty=\(awakePenalty), consistencyScore=\(consistencyScore)")
        return (totalScore, legend)
    }

    private func calculateConsistencyScore(date: Date) async -> Float {
        var bedtimes: [Float] = []
        let calendar = Calendar.current

        for i in 0..<7 {
            let pastDate = calendar.date(byAdding: .day, value: -i, to: date)!
            do {
                let response = try await strapiRepository.fetchSleepLog(date: pastDate)
                if !response.data.isEmpty {
                    if let log = response.data.first(where: { $0.sleepDuration > 0 }), let start = log.startTime {
                        let components = calendar.dateComponents([.hour, .minute], from: start)
                        let minutes = Float((components.hour ?? 0) * 60 + (components.minute ?? 0))
                        bedtimes.append(minutes)
                    }
                }
            } catch {
                Logger.sleep.error("Failed to fetch sleep log for \(pastDate): \(error.localizedDescription)")
            }
        }

        guard bedtimes.count >= 2 else { return 5 }

        let mean = bedtimes.reduce(0, +) / Float(bedtimes.count)
        let variance = bedtimes.map { pow($0 - mean, 2) }.reduce(0, +) / Float(bedtimes.count)
        let stdDev = sqrt(variance)

        return stdDev < 30 ? 15 : stdDev < 60 ? 10 : 5
    }

    private func calculateStreak(date: Date) async -> Int {
        var streak = 0
        let calendar = Calendar.current
        var currentDate = date

        while true {
            let recommendedHours = sleepGoal
            guard let response = try? await strapiRepository.fetchSleepLog(date: currentDate),
                  !response.data.isEmpty,
                  let log = response.data.first,
                  log.sleepDuration > 0,
                  log.sleepDuration >= recommendedHours * 0.9 else {
                break
            }
            streak += 1
            guard let prevDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = prevDate
        }

        return streak
    }

    private func formatDebt(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return "\(h)h\(m)m"
    }

    private func generateInsights(sleepData: HealthService.SleepData, debtMinutes: Int) -> [String] {
        var insights = [String]()
        let totalSleepHours = Float(sleepData.total / 3600)

        if debtMinutes > 0 {
            insights.append("Nap \(debtMinutes / 60)h\(debtMinutes % 60)m to cut sleep debt")
        }
        if totalSleepHours < sleepGoal * 0.8 {
            insights.append("Consider earlier bedtime for better rest")
        }
        if Float(sleepData.deep / 3600) < sleepGoal * 0.15 {
            insights.append("Increase deep sleep with relaxation techniques")
        }
        return insights.isEmpty ? ["Good sleep pattern today!"] : insights
    }

    private func getNextAlarmTime() async -> Date? {
        let center = UNUserNotificationCenter.current()
        return await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let now = Date()
                let tomorrow8AM = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: now.addingTimeInterval(24 * 3600))!

                let nextDates = requests.compactMap { $0.trigger as? UNCalendarNotificationTrigger }
                                        .compactMap { $0.nextTriggerDate() }

                if let earliest = nextDates.min(), earliest > now {
                    continuation.resume(returning: earliest)
                } else {
                    continuation.resume(returning: tomorrow8AM)
                }
            }
        }
    }

    private func setAlarm(alarmTime: Date) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Wake Up!"
        content.sound = UNNotificationSound.default

        let components = Calendar.current.dateComponents([.hour, .minute], from: alarmTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "sleepAlarm", content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            Logger.sleep.error("Failed to set alarm: \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    private func initializeFirstname() async {
        guard firstname == nil,
              let _ = authRepository.authState.userId,
              let _ = authRepository.authState.jwt else {
            return
        }
        
        do {
            let userProfile = try await strapiRepository.getUserProfile()
            self.firstname = userProfile.firstName ?? "User"
        } catch {
            Logger.sleep.error("Failed to initialize firstname: \(error.localizedDescription)")
            self.firstname = "User"
        }
    }
}
