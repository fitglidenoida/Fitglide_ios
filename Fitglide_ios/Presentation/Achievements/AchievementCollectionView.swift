//
//  AchievementCollectionView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import SwiftUI

struct AchievementCollectionView: View {
    @ObservedObject var achievementManager: AchievementManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedLevel: Int? = nil
    @State private var selectedCategory: Achievement.AchievementCategory? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with progress
                headerView
                
                // Level selector
                levelSelector
                
                // Achievements grid
                achievementsGridView
            }
            .navigationTitle("Achievement Collection")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAchievementDataFromStrapi()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Overall Progress
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Collection Progress")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(achievementManager.getUnlockedAchievements()) of \(achievementManager.getTotalAchievements())")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: achievementManager.getCompletionPercentage())
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(achievementManager.getCompletionPercentage() * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                
                // Current Level
                if let currentLevel = achievementManager.getCurrentLevel() {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Level")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(currentLevel.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(currentLevel.hindiName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(achievementManager.getLevelProgress() * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Level Selector
    private var levelSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(achievementManager.levelSystemEngine.levels) { level in
                    LevelBadgeCard(
                        level: level,
                        isSelected: selectedLevel == level.id,
                        progress: achievementManager.levelSystemEngine.getLevelProgress(level)
                    ) {
                        selectedLevel = selectedLevel == level.id ? nil : level.id
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Achievements Grid View
    private var achievementsGridView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Badges Section Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "medal.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        Text("Your Badges")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Collect badges by completing achievements and reaching milestones")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }
                
                // Achievement Categories
                ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: categoryIcon(for: category))
                                .foregroundColor(categoryColor(for: category))
                                .font(.title3)
                            
                            Text(category.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(getFilteredAchievements(for: category)) { achievement in
                                AchievementBadgeCard(
                                    achievement: achievement,
                                    isUnlocked: achievementManager.achievementsEngine.isAchievementUnlocked(id: achievement.id),
                                    progress: achievementManager.achievementsEngine.getAchievementProgress(id: achievement.id, currentValue: getCurrentValueForAchievement(achievement.id))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Helper Methods
    private func categoryIcon(for category: Achievement.AchievementCategory) -> String {
        switch category {
        case .fitness: return "figure.run"
        case .nutrition: return "leaf.fill"
        case .social: return "person.2.fill"
        case .streak: return "flame.fill"
        case .milestone: return "flag.fill"
        case .wellness: return "heart.fill"
        case .challenge: return "trophy.fill"
        }
    }
    
    private func categoryColor(for category: Achievement.AchievementCategory) -> Color {
        switch category {
        case .fitness: return .blue
        case .nutrition: return .green
        case .social: return .purple
        case .streak: return .orange
        case .milestone: return .red
        case .wellness: return .teal
        case .challenge: return .indigo
        }
    }
    
    // MARK: - Helper Methods
    private func getFilteredAchievements(for category: Achievement.AchievementCategory) -> [Achievement] {
        var achievements = achievementManager.achievementsEngine.getAchievementsByCategory(category)
        
        // Filter by selected level
        if let selectedLevel = selectedLevel {
            achievements = achievements.filter { $0.level == selectedLevel }
        }
        
        return achievements
    }
    
    // MARK: - Helper Methods
    private func getCurrentValueForAchievement(_ achievementId: String) -> Double {
        // Get current value from UserDefaults (set by Strapi sync)
        let currentValue = UserDefaults.standard.double(forKey: "achievement_current_value_\(achievementId)")
        return currentValue
    }
    
    private func loadAchievementDataFromStrapi() {
        Task {
            do {
                let authRepository = AuthRepository()
                let strapiRepository = StrapiRepository(authRepository: authRepository)
                let achievementLogs = try await strapiRepository.getAchievementLogs()
                
                await MainActor.run {
                    // Update UserDefaults with achievement data from Strapi
                    for log in achievementLogs.data {
                        if let achievementId = log.achievementId,
                           let currentValue = log.currentValue {
                            UserDefaults.standard.set(currentValue, forKey: "achievement_current_value_\(achievementId)")
                        }
                    }
                    UserDefaults.standard.synchronize()
                    print("AchievementCollectionView: Loaded \(achievementLogs.data.count) achievement logs from Strapi")
                }
            } catch {
                print("AchievementCollectionView: Failed to load achievement data from Strapi: \(error)")
            }
        }
    }
}

// MARK: - Level Badge Card
struct LevelBadgeCard: View {
    let level: Level
    let isSelected: Bool
    let progress: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Level Icon
                ZStack {
                    Circle()
                        .fill(
                            level.isUnlocked ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("\(level.id)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(level.isUnlocked ? .white : .gray)
                }
                
                // Level Name
                VStack(spacing: 2) {
                    Text(level.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .primary : .secondary)
                    
                    Text(level.hindiName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Progress
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: level.isUnlocked ? .blue : .gray))
                    .scaleEffect(y: 1.5)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Achievement Badge Card
struct AchievementBadgeCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(colors: achievement.badgeColor.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                
                // Show custom badge image if available, otherwise use SF Symbol
                if let badgeImageName = achievement.badgeImageName, !badgeImageName.isEmpty {
                    Image(badgeImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .opacity(isUnlocked ? 1.0 : 0.3)
                } else {
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(isUnlocked ? .white : .gray)
                }
                
                // Unlock indicator
                if isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .background(Circle().fill(.white).frame(width: 16, height: 16))
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            // Title
            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .lineLimit(2)
            
            // Progress
            if !isUnlocked {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
            }
            
            // FitCoins Reward
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                
                Text("\(achievement.fitCoinsReward)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Level Badge
            HStack {
                Text("L\(achievement.level)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(4)
                
                Spacer()
                
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

#Preview {
    AchievementCollectionView(achievementManager: AchievementManager.shared)
}
