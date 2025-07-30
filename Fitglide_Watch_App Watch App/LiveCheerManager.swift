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

class LiveCheerManager: ObservableObject {
    @Published var isLiveCheerEnabled = false
    @Published var cheerCount = 0
    @Published var selectedFriends: [String] = []
    @Published var selectedPacks: [String] = []
    @Published var isWorkoutActive = false
    @Published var currentWorkoutType = ""
    @Published var workoutStartTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private var cheerTimer: Timer?
    
    init() {
        setupNotifications()
        loadSettings()
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
        sendToStrapi(notificationData)
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
    
    private func sendToStrapi(_ data: [String: Any]) {
        // Send live cheer notification to Strapi backend
        guard let url = URL(string: "https://admin.fitglide.in/api/live-cheers") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("❌ Failed to send live cheer to Strapi: \(error.localizedDescription)")
                } else {
                    print("✅ Live cheer sent to Strapi successfully")
                }
            }.resume()
        } catch {
            print("❌ Failed to serialize live cheer data for Strapi: \(error.localizedDescription)")
        }
    }
    
    func receiveCheer() {
        DispatchQueue.main.async {
            self.cheerCount += 1
            self.triggerCheerHaptic()
        }
    }
    
    private func triggerCheerHaptic() {
        WKInterfaceDevice.current().play(.success)
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
} 