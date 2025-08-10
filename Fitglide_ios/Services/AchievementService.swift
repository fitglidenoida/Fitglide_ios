import Foundation
import Combine

@MainActor
class AchievementService: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var badges: [BadgeEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Achievement Loading
    func loadAchievements() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = authRepository.authState.userId else {
                errorMessage = "User ID not found"
                isLoading = false
                return
            }
            
            // Load achievements from weight-loss-stories collection
            let achievementsResponse = try await strapiRepository.getWeightLossStoriesForUser(userId: userId)
            let badgesResponse = try await strapiRepository.getBadges(userId: userId)
            
            // Convert to Achievement models
            self.achievements = achievementsResponse.data.map { story in
                Achievement(
                    id: story.documentId,
                    title: story.storyText ?? "Achievement",
                    description: story.storyText ?? "Goal achieved!",
                    icon: getAchievementIcon(for: story.storyId ?? "general"),
                    category: getAchievementCategory(for: story.storyId ?? "general"),
                    isUnlocked: true,
                    unlockedDate: parseDate(story.createdAt),
                    progress: 1.0,
                    target: 1.0,
                    level: 1,
                    fitCoinsReward: 50,
                    badgeImageName: story.storyId ?? "general",
                    isHidden: false,
                    unlockCondition: "Goal achieved"
                )
            }
            
            // Use BadgeEntry directly
            self.badges = badgesResponse.data
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load achievements: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Achievement Calculation
    func calculateAchievements(from healthData: HealthData) async {
        var newAchievements: [WeightLossStoryRequest] = []
        
        // Step achievements
        if let steps = healthData.steps {
            if steps >= 10000 && !hasAchievement(type: "steps_10k") {
                newAchievements.append(createAchievement(
                    title: "10K Steps",
                    description: "Walked 10,000 steps in a day",
                    storyType: "steps_10k",
                    goalAchievedText: "You walked 10,000 steps! Keep moving!"
                ))
            }
            
            if steps >= 15000 && !hasAchievement(type: "steps_15k") {
                newAchievements.append(createAchievement(
                    title: "15K Steps",
                    description: "Walked 15,000 steps in a day",
                    storyType: "steps_15k",
                    goalAchievedText: "Amazing! 15,000 steps achieved!"
                ))
            }
        }
        
        // Weight loss achievements
        if let weightLost = healthData.weightLost, weightLost >= 5.0 && !hasAchievement(type: "weight_5kg") {
            newAchievements.append(createAchievement(
                title: "5kg Lost",
                description: "Lost 5 kilograms",
                storyType: "weight_5kg",
                goalAchievedText: "Congratulations! You've lost 5kg!"
            ))
        }
        
        if let weightLost = healthData.weightLost, weightLost >= 10.0 && !hasAchievement(type: "weight_10kg") {
            newAchievements.append(createAchievement(
                title: "10kg Lost",
                description: "Lost 10 kilograms",
                storyType: "weight_10kg",
                goalAchievedText: "Incredible! You've lost 10kg!"
            ))
        }
        
        // Streak achievements
        if let streak = healthData.streak {
            if streak >= 7 && !hasAchievement(type: "streak_7") {
                newAchievements.append(createAchievement(
                    title: "Week Warrior",
                    description: "7-day activity streak",
                    storyType: "streak_7",
                    goalAchievedText: "You've maintained a 7-day streak!"
                ))
            }
            
            if streak >= 30 && !hasAchievement(type: "streak_30") {
                newAchievements.append(createAchievement(
                    title: "Monthly Master",
                    description: "30-day activity streak",
                    storyType: "streak_30",
                    goalAchievedText: "Amazing! 30-day streak achieved!"
                ))
            }
        }
        
        // Save new achievements
        for achievement in newAchievements {
            await saveAchievement(achievement)
        }
        
        // Reload achievements
        await loadAchievements()
    }
    
    // MARK: - Helper Methods
    private func hasAchievement(type: String) -> Bool {
        return achievements.contains { achievement in
            achievement.id.contains(type)
        }
    }
    
    private func createAchievement(
        title: String,
        description: String,
        storyType: String,
        goalAchievedText: String
    ) -> WeightLossStoryRequest {
        guard let userId = authRepository.authState.userId else {
            fatalError("User ID not found")
        }
        
        return WeightLossStoryRequest(
            storyId: UUID().uuidString,
            thenWeight: 0.0,
            nowWeight: 0.0,
            weightLost: 0.0,
            storyText: description,
            usersPermissionsUser: UserId(id: userId),
            visibility: "Everyone",
            beforeImage: nil,
            afterImage: nil
        )
    }
    
    private func saveAchievement(_ request: WeightLossStoryRequest) async {
        do {
            _ = try await strapiRepository.createWeightLossStory(request: request)
        } catch {
            print("Failed to save achievement: \(error)")
        }
    }
    
    private func getAchievementIcon(for type: String) -> String {
        switch type {
        case "steps_10k", "steps_15k":
            return "figure.walk"
        case "weight_5kg", "weight_10kg":
            return "scalemass.fill"
        case "streak_7", "streak_30":
            return "flame.fill"
        case "sleep_8h":
            return "bed.double.fill"
        case "water_goal":
            return "drop.fill"
        default:
            return "star.fill"
        }
    }
    
    private func getAchievementCategory(for type: String) -> Achievement.AchievementCategory {
        switch type {
        case "steps_10k", "steps_15k":
            return .fitness
        case "weight_5kg", "weight_10kg":
            return .milestone
        case "streak_7", "streak_30":
            return .streak
        case "sleep_8h":
            return .nutrition
        case "water_goal":
            return .nutrition
        default:
            return .milestone
        }
    }
    
    private func getBadgeColor(for type: String) -> String {
        switch type {
        case "gold":
            return "#FFD700"
        case "silver":
            return "#C0C0C0"
        case "bronze":
            return "#CD7F32"
        case "platinum":
            return "#E5E4E2"
        default:
            return "#FF6B6B"
        }
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.date(from: dateString)
    }
}

// MARK: - Supporting Models
struct HealthData {
    let steps: Int?
    let weightLost: Double?
    let streak: Int?
    let sleepHours: Double?
    let waterIntake: Double?
} 