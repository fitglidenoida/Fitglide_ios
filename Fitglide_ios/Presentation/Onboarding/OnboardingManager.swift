import Foundation
import SwiftUI

class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var hasSeenProfileSetup = false
    @Published var dismissedBanners: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    private let profileSetupKey = "hasSeenProfileSetup"
    private let dismissedBannersKey = "dismissedBanners"
    
    init() {
        loadOnboardingState()
    }
    
    func markOnboardingComplete() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }
    
    func markProfileSetupSeen() {
        hasSeenProfileSetup = true
        userDefaults.set(true, forKey: profileSetupKey)
    }
    
    func dismissBanner(for viewType: String) {
        dismissedBanners.insert(viewType)
        saveDismissedBanners()
    }
    
    func shouldShowBanner(for viewType: String) -> Bool {
        return !dismissedBanners.contains(viewType)
    }
    
    private func loadOnboardingState() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        hasSeenProfileSetup = userDefaults.bool(forKey: profileSetupKey)
        
        if let dismissedData = userDefaults.array(forKey: dismissedBannersKey) as? [String] {
            dismissedBanners = Set(dismissedData)
        }
    }
    
    private func saveDismissedBanners() {
        userDefaults.set(Array(dismissedBanners), forKey: dismissedBannersKey)
    }
}

// Extension to check profile completeness
extension OnboardingManager {
    func isProfileComplete(profileData: ProfileData?) -> Bool {
        guard let profile = profileData else { return false }
        
        let hasBasicInfo = !profile.firstName.isEmpty && !profile.lastName.isEmpty
        let hasHealthVitals = profile.height > 0 && profile.weight > 0 && profile.age > 0
        let hasActivityLevel = !profile.activityLevel.isEmpty
        let hasGoals = !profile.fitnessGoal.isEmpty
        
        return hasBasicInfo && hasHealthVitals && hasActivityLevel && hasGoals
    }
    
    func getProfileCompletionPercentage(profileData: ProfileData?) -> Double {
        guard let profile = profileData else { return 0.0 }
        
        var completedFields = 0
        let totalFields = 5
        
        if !profile.firstName.isEmpty && !profile.lastName.isEmpty {
            completedFields += 1
        }
        if profile.height > 0 && profile.weight > 0 && profile.age > 0 {
            completedFields += 1
        }
        if !profile.activityLevel.isEmpty {
            completedFields += 1
        }
        if !profile.fitnessGoal.isEmpty {
            completedFields += 1
        }
        if !profile.firstName.isEmpty {
            completedFields += 1
        }
        
        return Double(completedFields) / Double(totalFields)
    }
} 