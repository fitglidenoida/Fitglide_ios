//
//  LiveCheerService.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import Combine

@MainActor
class LiveCheerService: ObservableObject {
    @Published var activeCheers: [LiveCheer] = []
    @Published var isLiveCheerEnabled = true
    @Published var connectedFriends: [SocialData.Friend] = []
    
    private var workoutId: String?
    private var timer: Timer?
    private var strapiRepository: StrapiRepository
    private var authRepository: AuthRepository
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Live Cheer Management
    func startLiveCheer(workoutId: String) {
        self.workoutId = workoutId
        startPeriodicUpdates()
        fetchConnectedFriends()
    }
    
    func stopLiveCheer() {
        workoutId = nil
        stopPeriodicUpdates()
        activeCheers.removeAll()
    }
    
    func sendCheer(from friendId: String, message: String? = nil) {
        guard let workoutId = workoutId else { return }
        
        let cheer = LiveCheer(
            id: UUID().uuidString,
            workoutId: workoutId,
            fromUserId: friendId,
            message: message ?? "Keep going! 💪",
            timestamp: Date(),
            type: .motivation
        )
        
        Task {
            do {
                _ = try await strapiRepository.sendLiveCheer(cheer: cheer)
                await MainActor.run {
                    activeCheers.append(cheer)
                }
            } catch {
                print("Failed to send live cheer: \(error)")
            }
        }
    }
    
    func sendAchievementCheer(achievement: String) {
        guard let workoutId = workoutId else { return }
        
        let cheer = LiveCheer(
            id: UUID().uuidString,
            workoutId: workoutId,
            fromUserId: "system",
            message: "🎉 \(achievement) 🎉",
            timestamp: Date(),
            type: .achievement
        )
        
        Task {
            do {
                _ = try await strapiRepository.sendLiveCheer(cheer: cheer)
                await MainActor.run {
                    activeCheers.append(cheer)
                }
            } catch {
                print("Failed to send achievement cheer: \(error)")
            }
        }
    }
    
    // MARK: - Real-time Updates
    private func startPeriodicUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchNewCheers()
            }
        }
    }
    
    private func stopPeriodicUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchNewCheers() {
        guard let workoutId = workoutId else { return }
        
        Task {
            do {
                let newCheers = try await strapiRepository.getLiveCheers(workoutId: workoutId)
                await MainActor.run {
                    // Add only new cheers
                    let existingIds = Set(activeCheers.map { $0.id })
                    let newCheersToAdd = newCheers.filter { !existingIds.contains($0.id) }
                    activeCheers.append(contentsOf: newCheersToAdd)
                    
                    // Keep only last 20 cheers
                    if activeCheers.count > 20 {
                        activeCheers = Array(activeCheers.suffix(20))
                    }
                }
            } catch {
                print("Failed to fetch new cheers: \(error)")
            }
        }
    }
    
    private func fetchConnectedFriends() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else { return }
                let response = try await strapiRepository.getFriends(filters: [:])
                await MainActor.run {
                    // Convert FriendEntry to SocialData.Friend
                    connectedFriends = response.data.map { entry in
                        SocialData.Friend(
                            id: String(entry.id),
                            name: entry.senderName ?? entry.receiverName ?? "Unknown",
                            avatarUrl: nil, // FriendEntry doesn't have avatarUrl
                            isOnline: false, // FriendEntry doesn't have isOnline
                            lastActivity: nil // FriendEntry doesn't have lastActivity
                        )
                    }.filter { $0.isOnline }
                }
            } catch {
                print("Failed to fetch connected friends: \(error)")
            }
        }
    }
    
    // MARK: - Achievement Detection
    func checkForAchievements(workoutData: ActiveWorkoutData) {
        // Distance achievements
        if workoutData.distance >= 1000 && !hasAchievement("1km") {
            sendAchievementCheer(achievement: "1km milestone reached!")
        }
        
        if workoutData.distance >= 5000 && !hasAchievement("5km") {
            sendAchievementCheer(achievement: "5km milestone reached!")
        }
        
        if workoutData.distance >= 10000 && !hasAchievement("10km") {
            sendAchievementCheer(achievement: "10km milestone reached!")
        }
        
        // Duration achievements
        if workoutData.duration >= 1800 && !hasAchievement("30min") { // 30 minutes
            sendAchievementCheer(achievement: "30 minutes of activity!")
        }
        
        if workoutData.duration >= 3600 && !hasAchievement("1hour") { // 1 hour
            sendAchievementCheer(achievement: "1 hour of activity!")
        }
        
        // Pace achievements
        let pace = workoutData.duration / (workoutData.distance / 1000)
        if pace <= 300 && workoutData.distance >= 1000 && !hasAchievement("5minPace") { // 5 min/km
            sendAchievementCheer(achievement: "Great pace! Under 5 min/km!")
        }
    }
    
    private func hasAchievement(_ achievementId: String) -> Bool {
        return activeCheers.contains { $0.message.contains(achievementId) }
    }
    
    // MARK: - Public Methods
    func toggleLiveCheer() {
        isLiveCheerEnabled.toggle()
        if !isLiveCheerEnabled {
            stopLiveCheer()
        }
    }
    
    func clearCheers() {
        activeCheers.removeAll()
    }
}

// MARK: - Data Models
struct LiveCheer: Codable, Identifiable {
    let id: String
    let workoutId: String
    let fromUserId: String
    let message: String
    let timestamp: Date
    let type: CheerType
    
    enum CheerType: String, Codable {
        case motivation
        case achievement
        case challenge
        case milestone
    }
}

 