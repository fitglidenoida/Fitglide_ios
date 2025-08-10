//
//  EnhancedDailyWisdomCard.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import SwiftUI

struct EnhancedDailyWisdomCard: View {
    @ObservedObject var achievementManager: AchievementManager
    @ObservedObject var homeViewModel: HomeViewModel
    @State private var currentMessage: DesiMessage?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Daily Wisdom")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Main Message Display
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading wisdom...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 60)
            } else if let message = currentMessage {
                VStack(spacing: 8) {
                    // Message text
                    Text(message.messageText)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                    
                    // Message type indicator
                    HStack {
                        Image(systemName: getMessageIcon(for: message.messageType))
                            .foregroundColor(getMessageColor(for: message.messageType))
                            .font(.caption)
                        
                        Text(getMessageTypeLabel(for: message.messageType))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Priority indicator
                        HStack(spacing: 2) {
                            ForEach(1...10, id: \.self) { index in
                                Circle()
                                    .fill(index <= message.priority ? getMessageColor(for: message.messageType) : Color.gray.opacity(0.3))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                .frame(minHeight: 80)
            } else if !homeViewModel.homeData.maxMessage.today.isEmpty {
                // Use the today_line from maxMessage
                VStack(spacing: 8) {
                    Text(homeViewModel.homeData.maxMessage.today)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                    
                    Text("Daily Motivation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 80)
            } else {
                // Fallback message
                VStack(spacing: 8) {
                    Text("Aaj ka target: 10,000 steps! Challenge karo! 💪")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text("Daily Motivation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 80)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            loadBestMessage()
            // Also fetch max message if not already loaded
            if homeViewModel.homeData.maxMessage.today.isEmpty {
                Task {
                    await homeViewModel.fetchMaxMessage()
                }
            }
        }
    }
    
    // MARK: - Message Loading
    private func loadBestMessage() {
        guard let messageService = achievementManager.contextualMessageService else { return }
        
        isLoading = true
        
        Task {
            // Priority-based message selection
            var bestMessage: DesiMessage?
            
            // 1. Check for recent achievements (highest priority)
            if let recentAchievement = getRecentAchievement() {
                bestMessage = await messageService.getAchievementMessage(
                    for: recentAchievement,
                    userLevel: achievementManager.getCurrentLevel()?.id ?? 1
                )
            }
            
            // 2. Check for level up (high priority)
            if bestMessage == nil, let recentLevel = getRecentLevelUp() {
                bestMessage = await messageService.getLevelUpMessage(for: recentLevel)
            }
            
            // 3. Check for streak milestones (high priority)
            if bestMessage == nil, let streakDays = getStreakMilestone() {
                bestMessage = await messageService.getStreakMessage(for: streakDays)
            }
            
            // 4. Check for festival context (medium priority)
            if bestMessage == nil, let festival = messageService.getCurrentFestival() {
                bestMessage = await messageService.getFestivalMessage(for: festival)
            }
            
            // 5. Daily motivation (fallback)
            if bestMessage == nil {
                bestMessage = await messageService.getDailyMotivation(
                    userLevel: achievementManager.getCurrentLevel()?.id ?? 1
                )
            }
            
            await MainActor.run {
                currentMessage = bestMessage
                isLoading = false
            }
        }
    }
    

    
    // MARK: - Helper Methods
    private func getRecentAchievement() -> Achievement? {
        // Check for achievements unlocked in the last 24 hours
        // This would be implemented based on your achievement tracking
        return nil
    }
    
    private func getRecentLevelUp() -> Int? {
        // Check for level ups in the last 24 hours
        return nil
    }
    
    private func getStreakMilestone() -> Int? {
        // Check for streak milestones (3, 7, 14, 30, 100 days)
        let currentStreak = 7 // This would come from your streak tracking
        let milestones = [3, 7, 14, 30, 100]
        return milestones.contains(currentStreak) ? currentStreak : nil
    }
    
    private func getMessageIcon(for messageType: String) -> String {
        switch messageType {
        case "achievement_celebration": return "trophy.fill"
        case "level_up": return "star.fill"
        case "streak_milestone": return "flame.fill"
        case "festival_context": return "gift.fill"
        case "daily_motivation": return "sun.max.fill"
        case "progress_motivation": return "chart.line.uptrend.xyaxis"
        case "workout_completion": return "figure.run"
        case "wellness_reminder": return "heart.fill"
        default: return "quote.bubble.fill"
        }
    }
    
    private func getMessageColor(for messageType: String) -> Color {
        switch messageType {
        case "achievement_celebration": return .yellow
        case "level_up": return .orange
        case "streak_milestone": return .red
        case "festival_context": return .purple
        case "daily_motivation": return .blue
        case "progress_motivation": return .green
        case "workout_completion": return .cyan
        case "wellness_reminder": return .pink
        default: return .gray
        }
    }
    
    private func getMessageTypeLabel(for messageType: String) -> String {
        switch messageType {
        case "achievement_celebration": return "Achievement"
        case "level_up": return "Level Up"
        case "streak_milestone": return "Streak"
        case "festival_context": return "Festival"
        case "daily_motivation": return "Daily"
        case "progress_motivation": return "Progress"
        case "workout_completion": return "Workout"
        case "wellness_reminder": return "Wellness"
        default: return "Wisdom"
        }
    }
}

#Preview {
    EnhancedDailyWisdomCard(
        achievementManager: AchievementManager.shared,
        homeViewModel: HomeViewModel(
            strapiRepository: StrapiRepository(authRepository: AuthRepository()),
            authRepository: AuthRepository(),
            healthService: HealthService()
        )
    )
    .padding()
}
