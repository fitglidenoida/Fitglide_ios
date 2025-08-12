//
//  LiveCheerManager.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 27/07/25.
//

import Foundation
import WatchKit
import WatchConnectivity
import Combine

extension Notification.Name {
    static let cheerReceived = Notification.Name("cheerReceived")
}

class LiveCheerManager: ObservableObject {
    @Published var isLiveCheerEnabled = false
    @Published var cheerCount = 0
    @Published var selectedFriends: [String] = []
    @Published var selectedPacks: [String] = []
    @Published var isWorkoutActive = false
    @Published var currentWorkoutType = ""
    @Published var workoutStartTime: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var receivedCheers: [CheerService.StrapiCheer] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var cheerTimer: Timer?
    private let cheerService = CheerService()
    
    init() {
        setupNotifications()
        loadSettings()
        
        // Load cheers from Strapi on init
        Task {
            await loadCheersFromStrapi()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .workoutStarted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWorkoutStarted(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .workoutEnded,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleWorkoutEnded(notification)
        }
    }
    
    private func handleWorkoutStarted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let workoutType = userInfo["workoutType"] as? String,
              let startTime = userInfo["startTime"] as? Date else { return }
        
        DispatchQueue.main.async {
            self.isWorkoutActive = true
            self.currentWorkoutType = workoutType
            self.workoutStartTime = startTime
            
            if self.isLiveCheerEnabled {
                self.startLiveCheerSession()
            }
        }
    }
    
    private func handleWorkoutEnded(_ notification: Notification) {
        DispatchQueue.main.async {
            self.isWorkoutActive = false
            self.currentWorkoutType = ""
            self.workoutStartTime = nil
            self.stopLiveCheerSession()
        }
    }
    
    func enableLiveCheer() {
        isLiveCheerEnabled = true
        saveSettings()
        
        if isWorkoutActive {
            startLiveCheerSession()
        }
    }
    
    func disableLiveCheer() {
        isLiveCheerEnabled = false
        saveSettings()
        stopLiveCheerSession()
    }
    
    func addFriend(_ friendId: String) {
        if !selectedFriends.contains(friendId) {
            selectedFriends.append(friendId)
            saveSettings()
        }
    }
    
    func removeFriend(_ friendId: String) {
        selectedFriends.removeAll { $0 == friendId }
        saveSettings()
    }
    
    func addPack(_ packId: String) {
        if !selectedPacks.contains(packId) {
            selectedPacks.append(packId)
            saveSettings()
        }
    }
    
    func removePack(_ packId: String) {
        selectedPacks.removeAll { $0 == packId }
        saveSettings()
    }
    
    private func startLiveCheerSession() {
        guard isLiveCheerEnabled && isWorkoutActive else { return }
        
        // Send initial notification to friends and packs
        sendLiveCheerNotification()
        
        // Set up periodic notifications (every 5 minutes)
        cheerTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.sendLiveCheerNotification()
        }
    }
    
    private func stopLiveCheerSession() {
        cheerTimer?.invalidate()
        cheerTimer = nil
    }
    
    private func sendLiveCheerNotification() {
        guard isWorkoutActive,
              let startTime = workoutStartTime else { return }
        
        let workoutDuration = Date().timeIntervalSince(startTime)
        let durationString = formatDuration(workoutDuration)
        
        // Create notification payload
        let notificationData: [String: Any] = [
            "type": "live_cheer",
            "workoutType": currentWorkoutType,
            "duration": durationString,
            "startTime": startTime.timeIntervalSince1970,
            "friends": selectedFriends,
            "packs": selectedPacks
        ]
        
        // Send to iPhone app via WatchConnectivity
        sendToiPhone(notificationData)
        
        // Also send to Strapi backend
        Task {
            await sendToStrapi(notificationData)
        }
    }
    
    private func sendToiPhone(_ data: [String: Any]) {
        // Use WatchConnectivity to send data to iPhone
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState == WCSessionActivationState.activated {
                do {
                    let messageData = try JSONSerialization.data(withJSONObject: data)
                    session.sendMessageData(messageData, replyHandler: nil) { error in
                        print("❌ Failed to send live cheer to iPhone: \(error.localizedDescription)")
                    }
                } catch {
                    print("❌ Failed to serialize live cheer data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @MainActor
    private func sendToStrapi(_ data: [String: Any]) async {
        guard let workoutType = data["workoutType"] as? String,
              let duration = data["duration"] as? String,
              let startTime = data["startTime"] as? Double,
              let friends = data["friends"] as? [String],
              let packs = data["packs"] as? [String] else {
            print("❌ Invalid data format for live cheer")
            return
        }
        
        do {
            // Try direct Strapi API first
            let senderId = "current_user_id" // This should come from auth
            let message = "🔥 \(workoutType) workout in progress! Duration: \(duration)"
            
            if !friends.isEmpty {
                try await cheerService.sendLiveCheerToMultipleUsers(
                    senderId: senderId,
                    receiverIds: friends,
                    message: message,
                    workoutType: workoutType,
                    duration: duration,
                    startTime: startTime
                )
            }
            
            print("✅ Live cheers sent to Strapi successfully")
            
        } catch {
            print("❌ Direct Strapi failed: \(error)")
            // Watch app works independently - no iPhone dependency
        }
    }
    
    func receiveCheer() {
        DispatchQueue.main.async {
            self.cheerCount += 1
            self.triggerCheerHaptic()
            self.showCheerNotification()
        }
    }
    
    private func triggerCheerHaptic() {
        // Enhanced haptic feedback for cheers
        let device = WKInterfaceDevice.current()
        
        // Play a sequence of haptics for more engaging feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            device.play(.success)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            device.play(.click)
        }
    }
    
    private func showCheerNotification() {
        // Show a brief notification overlay
        // This will be implemented in the UI layer
        NotificationCenter.default.post(
            name: .cheerReceived,
            object: nil,
            userInfo: ["cheerCount": cheerCount]
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        isLiveCheerEnabled = defaults.bool(forKey: "liveCheerEnabled")
        selectedFriends = defaults.stringArray(forKey: "selectedFriends") ?? []
        selectedPacks = defaults.stringArray(forKey: "selectedPacks") ?? []
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isLiveCheerEnabled, forKey: "liveCheerEnabled")
        defaults.set(selectedFriends, forKey: "selectedFriends")
        defaults.set(selectedPacks, forKey: "selectedPacks")
    }
    
    // MARK: - Strapi Integration
    @MainActor
    func loadCheersFromStrapi() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try direct Strapi API first
            let userId = "current_user_id" // This should come from auth
            let cheers = try await cheerService.fetchCheers(userId: userId)
            receivedCheers = cheers
            cheerCount = cheers.count
            
        } catch {
            print("❌ Direct Strapi failed: \(error)")
            // No data available - show empty state
            receivedCheers = []
            cheerCount = 0
        }
        
        isLoading = false
    }
    
    // No mock data - show empty state when no data available
    
    @MainActor
    func loadLiveCheersFromStrapi() async {
        do {
            // TODO: Get userId from authentication
            let userId = "current_user_id" // This should come from auth
            
            let liveCheers = try await cheerService.fetchLiveCheers(userId: userId)
            
            // Filter for recent live cheers (last 24 hours)
            let recentLiveCheers = liveCheers.filter { cheer in
                if let createdAt = ISO8601DateFormatter().date(from: cheer.createdAt) {
                    return Date().timeIntervalSince(createdAt) < 86400 // 24 hours
                }
                return false
            }
            
            // Update cheer count with live cheers
            cheerCount = recentLiveCheers.count
            
        } catch {
            print("❌ Error loading live cheers: \(error)")
        }
    }
} 