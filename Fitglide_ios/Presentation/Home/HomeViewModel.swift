//
//  HomeViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//

import Foundation
import SwiftUI
import OSLog
import HealthKit
import UserNotifications

struct WeightLossStory: Identifiable, Codable, Equatable {
    let id: Int
    let storyId: String?
    let firstName: String?
    let thenWeight: Int?
    let nowWeight: Int?
    let weightLost: Int?
    let storyText: String?
    let thenPhotoUrl: String?
    let nowPhotoUrl: String?
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var homeData: HomeData
    @Published var uiMessage: String? = nil
    @Published var isLoading: Bool = true
    @Published var navigateToCreateStory: Bool = false
    @Published var date: Date = Date()
    @Published var sleepHours: Float = 0
    @Published var hydrationRemindersEnabled: Bool = false
    @Published var hydrationHistory: [HydrationEntry] = []
    @Published var wakeUpTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @Published var bedTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
    @Published var weightLossStories: [WeightLossStory] = []
    var healthVitals: [HealthVitalsEntry] = [] // Cache for health vitals
    
    // Periods tracking - now using real data
    @Published var periodsViewModel: PeriodsViewModel

    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    private let healthService: HealthService
    private let sharedPreferences: UserDefaults
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "Home")

    private var lastStepUpdateTime: TimeInterval = 0
    private let stepUpdateInterval: TimeInterval = 1 // 1 second
    private var liveUpdateTimer: Timer?
    
    // Computed properties for cycle tracking from real data
    var cycleDay: Int {
        return periodsViewModel.currentCycleDay
    }
    
    var daysUntilNextPeriod: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: periodsViewModel.nextPeriodDate).day ?? 0
    }
    
    var cycleProgress: Double {
        return periodsViewModel.cycleProgress
    }
    
    var cycleProgressPercentage: Int {
        return Int(periodsViewModel.cycleProgressPercentage)
    }
    
    private func updateCycleTrackingData() {
        // This is now handled by the PeriodsViewModel with real HealthKit data
        // The computed properties above will automatically reflect the latest data
    }

    init(
        strapiRepository: StrapiRepository,
        authRepository: AuthRepository,
        healthService: HealthService
    ) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.healthService = healthService
        self.sharedPreferences = UserDefaults.standard
        
        // Initialize PeriodsViewModel with real HealthKit data
        self.periodsViewModel = PeriodsViewModel(
            healthService: healthService,
            strapiRepository: strapiRepository,
            authRepository: authRepository
        )

        self.homeData = HomeData(
            firstName: "User",
            watchSteps: 0,
            manualSteps: 0,
            trackedSteps: 0,
            stepGoal: 10000,
            sleepHours: 0,
            caloriesBurned: 0,
            heartRate: 0,
            maxHeartRate: 190,
            hydration: 0,
            hydrationGoal: 2.5,
            caloriesLogged: 0,
            bmr: 2000,
            stressScore: 0,
            showStories: true,
            storiesOrLeaderboard: ["User: 10K steps"],
            isTracking: false,
            paused: false,
            dateRangeMode: "Day",
            badges: [],
            healthVitalsUpdated: false,
            customStartDate: nil,
            customEndDate: nil,
            maxMessage: MaxMessage(yesterday: "", today: "", hasPlayed: false),
            challenges: []
        )

        self.hydrationRemindersEnabled = sharedPreferences.bool(forKey: "hydrationRemindersEnabled")
        if let wakeUpTimeInterval = sharedPreferences.object(forKey: "wakeUpTime") as? Double {
            self.wakeUpTime = Date(timeIntervalSinceReferenceDate: wakeUpTimeInterval)
        }
        if let bedTimeInterval = sharedPreferences.object(forKey: "bedTime") as? Double {
            self.bedTime = Date(timeIntervalSinceReferenceDate: bedTimeInterval)
        }

        Task {
            await initialize()
            await fetchWeightLossStories()
            updateCycleTrackingData()
        }
    }
    
    private func initialize() async {
        logger.debug("HomeViewModel initialized")
        clearSharedPreferences()
        
        if !authRepository.isLoggedIn() {
            logger.debug("Waiting for auth state to be initialized...")
            try? await Task.sleep(nanoseconds: 100_000_000)
            Task { await initialize() }
            return
        }
        
        let authState = authRepository.authState
        let firstName = authState.firstName ?? "User"
        logger.debug("Fetched initial authState: id=\(authState.userId ?? "nil"), firstName=\(firstName)")
        
        let vitals = await fetchInitialData()
        let age = vitals?.date_of_birth.flatMap { dob -> Int? in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let birthDate = formatter.date(from: dob) else { return nil }
            return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
        } ?? 30
        
        // Fetch sleep logs for wake-up and bedtime
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sleepLogs = try? await strapiRepository.fetchSleepLog(date: today)
        if let sleepLog = sleepLogs?.data.first {
            if let endTime = sleepLog.endTime {
                self.wakeUpTime = endTime
                sharedPreferences.set(endTime.timeIntervalSinceReferenceDate, forKey: "wakeUpTime")
            }
            if let startTime = sleepLog.startTime {
                self.bedTime = startTime
                sharedPreferences.set(startTime.timeIntervalSinceReferenceDate, forKey: "bedTime")
            }
            sharedPreferences.synchronize()
            logger.debug("Fetched sleep log: wakeUpTime=\(self.wakeUpTime), bedTime=\(self.bedTime)")
        }
        
        // Update homeData in smaller steps
        homeData = homeData.copy(
            firstName: firstName,
            maxHeartRate: Float(220 - age),
            healthVitalsUpdated: vitals != nil
        )
        
        homeData = homeData.copy(
            watchSteps: sharedPreferences.float(forKey: "steps"),
            trackedSteps: sharedPreferences.float(forKey: "trackedSteps"),
            stepGoal: Float(vitals?.stepGoal ?? 10000),
            sleepHours: sharedPreferences.float(forKey: "sleepHours"),
            caloriesBurned: sharedPreferences.float(forKey: "caloriesBurned"),
            heartRate: sharedPreferences.float(forKey: "heartRate"),
            hydration: sharedPreferences.float(forKey: "hydration"),
            hydrationGoal: Float(vitals?.waterGoal ?? 2.5),
            caloriesLogged: 0,
            bmr: vitals?.calorieGoal ?? sharedPreferences.integer(forKey: "bmr")
        )
        
        homeData = homeData.copy(
            showStories: sharedPreferences.bool(forKey: "show_stories"),
            isTracking: sharedPreferences.bool(forKey: "isTracking"),
            paused: sharedPreferences.bool(forKey: "isPaused")
        )
        
        await refreshData()
        await scheduleHydrationReminders()
        isLoading = false
    }
    
    private func clearSharedPreferences() {
        sharedPreferences.removeObject(forKey: "steps")
        sharedPreferences.removeObject(forKey: "trackedSteps")
        sharedPreferences.removeObject(forKey: "sleepHours")
        sharedPreferences.removeObject(forKey: "caloriesBurned")
        sharedPreferences.removeObject(forKey: "heartRate")
        sharedPreferences.removeObject(forKey: "hydration")
        sharedPreferences.removeObject(forKey: "bmr")
        sharedPreferences.removeObject(forKey: "isPaused")
        sharedPreferences.removeObject(forKey: "isTracking")
        sharedPreferences.synchronize()
        logger.debug("Cleared SharedPreferences for metrics")
    }
    
    private func fetchInitialData() async -> HealthVitalsEntry? {
        guard let userId = authRepository.authState.userId,
              let _ = authRepository.authState.jwt else {
            logger.error("Missing userId or token")
            return nil
        }
        
        do {
            let response = try await strapiRepository.getHealthVitals(userId: userId)
            self.healthVitals = response.data // Store in cache
            let vitals = response.data.first
            logger.debug("Fetched HealthVitals: \(String(describing: vitals))")
            return vitals
        } catch {
            logger.error("Error fetching HealthVitals: \(error.localizedDescription)")
            return nil
        }
    }
    

    
    func refreshData() async {
        logger.debug("Refreshing home data")
        
        let calendar = Calendar.current
        let sleepDate = calendar.startOfDay(for: self.date)
        let sleepLogs = try? await strapiRepository.fetchSleepLog(date: sleepDate)
        
        let rawSleepHours = sleepLogs?.data.first?.sleepDuration ?? 0
        let actualSleepTime = Float(rawSleepHours)
        logger.debug("Fetched sleep log for: \(sleepDate), hours: \(actualSleepTime)")
        
        if sleepLogs?.data.first == nil {
            logger.debug("No sleep log found for \(sleepDate)")
        }
        
        let steps: Int64 = (try? await healthService.getSteps(date: date)) ?? 0
        let hydration: Double = (try? await healthService.getHydration(date: date)) ?? 0.0
        let heartRateData: HealthService.HeartRateData? = (try? await healthService.getHeartRate(date: date))
        let calories: Float = (try? await healthService.getCaloriesBurned(date: date)) ?? 0.0
        let hrvData: HealthService.HRVData? = (try? await healthService.getHRV(date: date))
        
        let heartRateAvg: Float = Float(heartRateData?.average ?? 0)
        let sdnn: Float = hrvData?.sdnn ?? 0.0
        
        let stressScore = calculateStressScore(
            sleepHours: actualSleepTime,
            steps: steps,
            calories: Double(calories),
            hrv: sdnn
        )
        
        let challenges = await fetchAcceptedChallenges()
        let hydrationHistory = await fetchHydrationHistory()
        
        homeData = homeData.copy(
            watchSteps: Float(steps),
            sleepHours: actualSleepTime,
            caloriesBurned: calories,
            heartRate: heartRateAvg,
            hydration: Float(hydration),
            stressScore: stressScore,
            challenges: challenges
        )
        
        self.hydrationHistory = hydrationHistory
        
        sharedPreferences.set(homeData.watchSteps, forKey: "steps")
        sharedPreferences.set(homeData.hydration, forKey: "hydration")
        sharedPreferences.set(homeData.heartRate, forKey: "heartRate")
        sharedPreferences.set(homeData.caloriesBurned, forKey: "caloriesBurned")
        sharedPreferences.set(homeData.sleepHours, forKey: "sleepHours")
        sharedPreferences.set(homeData.bmr, forKey: "bmr")
        sharedPreferences.set(homeData.hydrationGoal, forKey: "hydrationGoal")
        sharedPreferences.synchronize()
        
        if authRepository.authState.jwt != nil {
            do {
                let badgesResponse = try await withTimeout(seconds: 10.0) {
                    try await self.strapiRepository.getBadges()
                }
                if let badges = badgesResponse?.data {
                    let mappedBadges = badges.compactMap { badge -> Badge? in
                        guard let url = badge.icon?.url else { return nil }
                        let fullUrl = url.starts(with: "http") ? url : "https://admin.fitglide.in\(url)"
                        return Badge(id: badge.id, title: badge.name, description: badge.description, iconUrl: fullUrl)
                    }
                    let earnedBadges = assignBadges(data: homeData, badges: mappedBadges)
                    homeData = homeData.copy(badges: earnedBadges)
                    logger.debug("Fetched badges: \(mappedBadges.count), earned: \(earnedBadges.count)")
                }
            } catch {
                logger.error("Badge fetch failed: \(error.localizedDescription)")
            }
        }
        
        logger.debug("Updated homeData: steps=\(self.homeData.watchSteps), sleepHours=\(self.homeData.sleepHours), stressScore=\(self.homeData.stressScore), challenges=\(self.homeData.challenges.count)")
    }
    
    // MARK: - Live Updates
    func startLiveUpdates() {
        stopLiveUpdates() // Stop any existing timer
        
        // Update every 30 seconds for real-time data
        liveUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
        
        logger.debug("Started live updates")
    }
    
    func stopLiveUpdates() {
        liveUpdateTimer?.invalidate()
        liveUpdateTimer = nil
        logger.debug("Stopped live updates")
    }
    
    deinit {
        stopLiveUpdates()
    }
    
    private func fetchAcceptedChallenges() async -> [Challenge] {
        guard let userId = authRepository.authState.userId else {
            logger.error("Missing userId for challenges")
            return []
        }
        
        do {
            let response = try await strapiRepository.getAcceptedChallenges(userId: userId)
            let challenges = response.data.map { challenge in
                Challenge(
                    id: String(challenge.id),
                    title: challenge.type,
                    description: "Challenge goal: \(challenge.goal)",
                    type: .solo,
                    goal: Double(challenge.goal),
                    current: 0.0,
                    unit: "steps",
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days from now
                    participants: [],
                    status: Challenge.ChallengeStatus(rawValue: challenge.challengeStatus ?? "active") ?? .active
                )
            }
            logger.debug("Fetched \(challenges.count) accepted challenges")
            return challenges
        } catch {
            logger.error("Error fetching challenges: \(error.localizedDescription)")
            return []
        }
    }
    
    private func calculateStressScore(
        sleepHours: Float,
        steps: Int64,
        calories: Double,
        hrv: Float?
    ) -> Int {
        let sdnn = hrv ?? 0
        var baseStress: Int = {
            switch sdnn {
            case 60...: return 1
            case 30..<60: return 2
            case ..<30: return 3
            default: return 2
            }
        }()
        let stepTotal = Int(homeData.trackedSteps) + Int(steps)
        let caloriesTotal = Int(calories)
        let isHighEffort = stepTotal > 15000 || caloriesTotal > 800
        let isLowEffort = stepTotal < 4000 && caloriesTotal < 300
        if baseStress == 1 && isHighEffort {
            baseStress = 2
        } else if baseStress == 3 && isLowEffort {
            baseStress = 2
        }
        return baseStress
    }
    
    private func assignBadges(data: HomeData, badges: [Badge]) -> [Badge] {
        var earnedBadges: [Badge] = []
        let totalSteps = data.watchSteps + data.manualSteps + data.trackedSteps
        
        for badge in badges {
            switch badge.title {
            case "Step Sultan":
                if totalSteps >= 10000 { earnedBadges.append(badge) }
            case "Hydration Hero":
                if data.hydration >= data.hydrationGoal { earnedBadges.append(badge) }
            case "Sleep Maharaja":
                if data.sleepHours >= 7.5 { earnedBadges.append(badge) }
            case "Dumbbell Daaku":
                if data.caloriesBurned >= 500 { earnedBadges.append(badge) }
            case "Yoga Yodha":
                if totalSteps >= 5000 && data.heartRate <= 85 { earnedBadges.append(badge) }
            case "Josh Machine":
                if totalSteps > 8000 && data.caloriesBurned > 450 && data.sleepHours > 7 {
                    earnedBadges.append(badge)
                }
            case "Cycle Rani":
                if totalSteps >= 5000 { earnedBadges.append(badge) }
            case "Max Ka Dost":
                if data.sleepHours >= 7 { earnedBadges.append(badge) }
            default:
                break
            }
        }
        
        return earnedBadges
    }
    
    func startTracking(workoutType: String = "Walking") {
        if !homeData.isTracking {
            logger.debug("Starting tracking with workoutType: \(workoutType)")
            let initialSteps = sharedPreferences.float(forKey: "trackedSteps")
            let isPaused = sharedPreferences.bool(forKey: "isPaused")
            homeData = homeData.copy(
                trackedSteps: initialSteps,
                isTracking: true,
                paused: isPaused
            )
            sharedPreferences.set(true, forKey: "isTracking")
            sharedPreferences.synchronize()
            postUiMessage("Tracking started: \(workoutType)")
        }
    }
    
    func stopTracking() {
        if homeData.isTracking {
            logger.debug("Stopping tracking")
            homeData = homeData.copy(
                trackedSteps: 0,
                isTracking: false,
                paused: false
            )
            sharedPreferences.removeObject(forKey: "trackedSteps")
            sharedPreferences.removeObject(forKey: "isTracking")
            sharedPreferences.removeObject(forKey: "isPaused")
            sharedPreferences.synchronize()
            postUiMessage("Tracking stopped")
        }
    }
    
    func updateTrackedSteps(steps: Float) {
        if homeData.isTracking {
            let currentTime = Date().timeIntervalSince1970
            if currentTime - lastStepUpdateTime >= stepUpdateInterval {
                if abs(steps - homeData.trackedSteps) > 0.1 {
                    homeData = homeData.copy(
                        trackedSteps: steps,
                        isTracking: homeData.isTracking,
                        paused: homeData.paused
                    )
                    sharedPreferences.set(steps, forKey: "trackedSteps")
                    sharedPreferences.synchronize()
                    logger.debug("Updated tracked steps: \(steps)")
                    lastStepUpdateTime = currentTime
                }
            }
        }
    }
    
    func togglePause() {
        let newPaused = !homeData.paused
        homeData = homeData.copy(paused: newPaused)
        sharedPreferences.set(newPaused, forKey: "isPaused")
        sharedPreferences.synchronize()
        logger.debug("Toggled pause state to: \(newPaused)")
        postUiMessage(newPaused ? "Tracking paused" : "Tracking resumed")
    }
    
    func toggleStoriesOrLeaderboard() {
        let newShowStories = !homeData.showStories
        homeData = homeData.copy(showStories: newShowStories)
        sharedPreferences.set(newShowStories, forKey: "show_stories")
        sharedPreferences.synchronize()
    }
    
    func setDateRangeMode(mode: String) {
        homeData = homeData.copy(
            dateRangeMode: mode,
            customStartDate: mode == "Custom" ? homeData.customStartDate : nil,
            customEndDate: mode == "Custom" ? homeData.customEndDate : nil
        )
    }
    
    func setCustomDateRange(start: Date?, end: Date?) {
        if let start = start, let end = end, end < start {
            homeData = homeData.copy(customStartDate: start, customEndDate: start)
            logger.debug("End date before start, setting end to start: \(start)")
        } else {
            homeData = homeData.copy(customStartDate: start, customEndDate: end)
            logger.debug("Set custom date range: start=\(String(describing: start)), end=\(String(describing: end))")
        }
        
        if start != nil && end != nil {
            Task {
                await refreshData()
            }
        }
    }
    
    func updateDate(_ newDate: Date) {
        date = newDate
        Task {
            await refreshData()
        }
    }
    
    func onCreateStoryClicked() {
        navigateToCreateStory = true
    }
    
    func onNavigationHandled() {
        navigateToCreateStory = false
    }
    
    func logWaterIntake(amount: Float = 0.25) async {
        let newHydration = homeData.hydration + amount
        homeData = homeData.copy(hydration: newHydration)
        sharedPreferences.set(newHydration, forKey: "hydration")
        sharedPreferences.synchronize()
        logger.debug("Logged water intake: \(newHydration)L")
        
        do {
            try await healthService.logWaterIntake(amount: Double(amount), date: Date())
            let message = motivationalMessages.randomElement() ?? "Great job staying hydrated!"
            postUiMessage("\(message) Added \(String(format: "%.2f", amount))L water intake")
            
            let newEntry = HydrationEntry(date: Date(), amount: amount)
            hydrationHistory.append(newEntry)
            sharedPreferences.set(try? JSONEncoder().encode(hydrationHistory), forKey: "hydrationHistory")
            sharedPreferences.synchronize()
        } catch {
            logger.error("Failed to log water to HealthKit: \(error.localizedDescription)")
            postUiMessage("Failed to log water: \(error.localizedDescription)")
        }
    }
    
    func markMaxMessagePlayed() {
        homeData = homeData.copy(maxMessage: MaxMessage(
            yesterday: homeData.maxMessage.yesterday,
            today: homeData.maxMessage.today,
            hasPlayed: true
        ))
    }
    
    func setHydrationReminderSettings(enabled: Bool, wakeUpTime: Date, bedTime: Date) async {
        hydrationRemindersEnabled = enabled
        self.wakeUpTime = wakeUpTime
        self.bedTime = bedTime
        sharedPreferences.set(enabled, forKey: "hydrationRemindersEnabled")
        sharedPreferences.set(wakeUpTime.timeIntervalSinceReferenceDate, forKey: "wakeUpTime")
        sharedPreferences.set(bedTime.timeIntervalSinceReferenceDate, forKey: "bedTime")
        sharedPreferences.synchronize()
        logger.debug("Set hydration reminder settings: enabled=\(enabled), wakeUp=\(wakeUpTime), bedTime=\(bedTime)")
        
        await scheduleHydrationReminders()
    }
    
    func scheduleHydrationReminders() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard hydrationRemindersEnabled else {
            logger.debug("Hydration reminders disabled")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let wakeUpComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTime)
        let bedTimeComponents = calendar.dateComponents([.hour, .minute], from: bedTime)
        
        guard let wakeUp = calendar.date(bySettingHour: wakeUpComponents.hour!, minute: wakeUpComponents.minute!, second: 0, of: startOfDay),
              let bedTime = calendar.date(bySettingHour: bedTimeComponents.hour!, minute: bedTimeComponents.minute!, second: 0, of: startOfDay) else {
            logger.error("Failed to set wake-up or bedtime")
            return
        }
        
        var startTime = wakeUp
        if startTime < now {
            startTime = calendar.date(byAdding: .day, value: 1, to: startTime)!
        }
        let endTime = max(startTime, bedTime < now ? calendar.date(byAdding: .day, value: 1, to: bedTime)! : bedTime)
        
        let totalSeconds = endTime.timeIntervalSince(startTime)
        let numIntervals = max(1, Int(totalSeconds / (2 * 3600))) // ~2-hour intervals
        let intervalSeconds = Int(totalSeconds) / numIntervals
        let waterPerInterval = homeData.hydrationGoal / Float(numIntervals)
        
        var currentTime = startTime
        while currentTime < endTime {
            let content = UNMutableNotificationContent()
            content.title = "Time to Hydrate!"
            content.body = "Drink \(String(format: "%.2f", waterPerInterval))L to stay on track!"
            content.sound = .default
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            do {
                try await UNUserNotificationCenter.current().add(request)
                logger.debug("Scheduled hydration reminder at \(currentTime) for \(waterPerInterval)L")
            } catch {
                logger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
            
            currentTime = calendar.date(byAdding: .second, value: intervalSeconds, to: currentTime)!
        }
    }
    
    private func fetchHydrationHistory() async -> [HydrationEntry] {
        if let data = sharedPreferences.data(forKey: "hydrationHistory"),
           let history = try? JSONDecoder().decode([HydrationEntry].self, from: data) {
            return history
        }
        
        let calendar = Calendar.current
        var history: [HydrationEntry] = []
        for day in -6...0 {
            if let date = calendar.date(byAdding: .day, value: day, to: calendar.startOfDay(for: Date())) {
                do {
                    let amount = try await healthService.getHydration(date: date)
                    if amount > 0 {
                        history.append(HydrationEntry(date: date, amount: Float(amount)))
                    }
                } catch {
                    logger.error("Failed to fetch hydration for \(date): \(error.localizedDescription)")
                }
            }
        }
        return history
    }
    
    func logWaterToStrapi(amount: Float = 0.25) async {
        guard authRepository.authState.userId != nil else {
            print("User ID missing")
            return
        }
        
        let selectedDate = Calendar.current.startOfDay(for: date)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formattedDate = formatter.string(from: selectedDate)
        
        do {
            let response = try await strapiRepository.getHealthLog(date: formattedDate, source: "HealthKit")
            let existing = response.data.first
            
            let newWater = (existing?.waterIntake ?? 0) + amount
            
            _ = try await strapiRepository.syncHealthLog(
                date: formattedDate,
                steps: existing?.steps ?? 0,
                hydration: newWater,
                heartRate: existing?.heartRate,
                caloriesBurned: existing?.caloriesBurned,
                source: "HealthKit",
                documentId: existing?.documentId
            )
            
            // ✅ Immediately update UI model
            homeData = homeData.copy(hydration: Float(newWater))
            sharedPreferences.set(Float(newWater), forKey: "hydration")
            sharedPreferences.synchronize()
            
            postUiMessage("Hydration logged: \(String(format: "%.2f", newWater))L")
            
        } catch {
            print("Error logging hydration to health log: \(error)")
            postUiMessage("Failed to log hydration")
        }
    }
    
    
    private func postUiMessage(_ message: String) {
        uiMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            uiMessage = nil
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T? {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            guard let result = try await group.next() else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
            }
            group.cancelAll()
            return result
        }
    }
    
    func fetchWeightLossStories() async {
        do {
            let response = try await strapiRepository.getWeightLossStories()
            
            let mapped = response.data.map { item in
                WeightLossStory(
                    id: item.id,
                    storyId: item.storyId ?? "",
                    firstName: item.usersPermissionsUser?.firstName ?? "Anonymous",
                    thenWeight: item.thenWeight.map { Int($0) },
                    nowWeight: item.nowWeight.map { Int($0) },
                    weightLost: item.weightLost.map { Int($0) },
                    storyText: item.storyText ?? "",
                    thenPhotoUrl: item.beforeImage?.url,
                    nowPhotoUrl: item.afterImage?.url
                )
            }
            
            DispatchQueue.main.async {
                self.weightLossStories = mapped
            }
        } catch {
            print("Failed to fetch weight loss stories: \(error)")
        }
    }

    
    private let motivationalMessages = [
        "Awesome job! Keep sipping to stay refreshed!",
        "You're crushing it! Another glass, and you're a hydration hero!",
        "Water is life—great work keeping hydrated!",
        "One more sip closer to your daily goal!",
        "Stay hydrated, stay unstoppable!"
    ]
    
    public func fetchMaxMessage() async {
        guard !homeData.maxMessage.hasPlayed else {
            logger.debug("Max message already played today.")
            return
        }
        
        do {
            let response = try await strapiRepository.getDesiMessages()
            let messages = response.data
            
            let performanceSummary: String = {
                if homeData.watchSteps >= 10000 && homeData.sleepHours >= 7 && homeData.hydration >= homeData.hydrationGoal {
                    return "Kal to tu sher tha, sab kuch complete kar diya!"
                } else if homeData.watchSteps >= 10000 {
                    return "Steps to full maar diye kal, baaki aur bhi jeetna baaki hai!"
                } else if homeData.sleepHours >= 7 {
                    return "Achi neend li kal, ab steps aur pani pe dhyan de bhai!"
                } else if homeData.hydration >= homeData.hydrationGoal {
                    return "Hydration full tha kal ka, ab thoda chal bhi le!"
                } else {
                    return "Kal halka tha bhai, aaj pakka fire hona hai!"
                }
            }()
            
            if let random = messages.randomElement() {
                let yesterday = performanceSummary
                let today = random.todayLine
                
                homeData = homeData.copy(maxMessage: MaxMessage(
                    yesterday: yesterday,
                    today: today,
                    hasPlayed: false
                ))
                
                sharedPreferences.set(yesterday, forKey: "maxMessageYesterday")
                sharedPreferences.set(today, forKey: "maxMessageToday")
                sharedPreferences.set(false, forKey: "maxMessageHasPlayed")
                sharedPreferences.synchronize()
                
                logger.debug("Fetched Max message: \(yesterday) | \(today)")
            } else {
                logger.error("No desi messages returned from API.")
            }
        } catch {
            logger.error("Failed to fetch desi messages: \(error.localizedDescription)")
        }
    }
}
struct HomeData: Equatable {
    let firstName: String
    let watchSteps: Float
    let manualSteps: Float
    let trackedSteps: Float
    let stepGoal: Float
    let sleepHours: Float
    let caloriesBurned: Float
    let heartRate: Float
    let maxHeartRate: Float
    let hydration: Float
    let hydrationGoal: Float
    let caloriesLogged: Float
    let bmr: Int
    let stressScore: Int
    let showStories: Bool
    let storiesOrLeaderboard: [String]
    let isTracking: Bool
    let paused: Bool
    let dateRangeMode: String
    let badges: [Badge]
    let healthVitalsUpdated: Bool
    let customStartDate: Date?
    let customEndDate: Date?
    let maxMessage: MaxMessage
    let challenges: [Challenge]
    
    func copy(
        firstName: String? = nil,
        watchSteps: Float? = nil,
        manualSteps: Float? = nil,
        trackedSteps: Float? = nil,
        stepGoal: Float? = nil,
        sleepHours: Float? = nil,
        caloriesBurned: Float? = nil,
        heartRate: Float? = nil,
        maxHeartRate: Float? = nil,
        hydration: Float? = nil,
        hydrationGoal: Float? = nil,
        caloriesLogged: Float? = nil,
        bmr: Int? = nil,
        stressScore: Int? = nil,
        showStories: Bool? = nil,
        storiesOrLeaderboard: [String]? = nil,
        isTracking: Bool? = nil,
        paused: Bool? = nil,
        dateRangeMode: String? = nil,
        badges: [Badge]? = nil,
        healthVitalsUpdated: Bool? = nil,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil,
        maxMessage: MaxMessage? = nil,
        challenges: [Challenge]? = nil
    ) -> HomeData {
        HomeData(
            firstName: firstName ?? self.firstName,
            watchSteps: watchSteps ?? self.watchSteps,
            manualSteps: manualSteps ?? self.manualSteps,
            trackedSteps: trackedSteps ?? self.trackedSteps,
            stepGoal: stepGoal ?? self.stepGoal,
            sleepHours: sleepHours ?? self.sleepHours,
            caloriesBurned: caloriesBurned ?? self.caloriesBurned,
            heartRate: heartRate ?? self.heartRate,
            maxHeartRate: maxHeartRate ?? self.maxHeartRate,
            hydration: hydration ?? self.hydration,
            hydrationGoal: hydrationGoal ?? self.hydrationGoal,
            caloriesLogged: caloriesLogged ?? self.caloriesLogged,
            bmr: bmr ?? self.bmr,
            stressScore: stressScore ?? self.stressScore,
            showStories: showStories ?? self.showStories,
            storiesOrLeaderboard: storiesOrLeaderboard ?? self.storiesOrLeaderboard,
            isTracking: isTracking ?? self.isTracking,
            paused: paused ?? self.paused,
            dateRangeMode: dateRangeMode ?? self.dateRangeMode,
            badges: badges ?? self.badges,
            healthVitalsUpdated: healthVitalsUpdated ?? self.healthVitalsUpdated,
            customStartDate: customStartDate ?? self.customStartDate,
            customEndDate: customEndDate ?? self.customEndDate,
            maxMessage: maxMessage ?? self.maxMessage,
            challenges: challenges ?? self.challenges
        )
    }
}

struct HydrationEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let amount: Float
}

struct Badge: Equatable, Codable {
    let id: Int
    let title: String
    let description: String
    let iconUrl: String
}

struct MaxMessage: Equatable, Codable {
    let yesterday: String
    let today: String
    let hasPlayed: Bool
}

// Challenge is defined in CommonDataModels.swift

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
