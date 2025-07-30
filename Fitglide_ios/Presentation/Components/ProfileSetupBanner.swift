import SwiftUI

struct ProfileSetupBanner: View {
    @State private var showOnboarding = false
    @State private var showProfile = false
    let profileData: ProfileData?
    let colorScheme: ColorScheme
    
    var body: some View {
        if shouldShowBanner {
            VStack(spacing: 0) {
                // Main banner
                Button(action: {
                    showOnboarding = true
                }) {
                    HStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bannerTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                            
                            Text(bannerDescription)
                                .font(.system(size: 14))
                                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        // Action button
                        HStack(spacing: 8) {
                            Text("Setup")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FitGlideTheme.colors(for: colorScheme).surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Quick action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        showProfile = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 14))
                            Text("Go to Profile")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                        )
                    }
                    
                    Spacer()
                    
                    Button("Dismiss") {
                        // TODO: Mark as dismissed for this session
                    }
                    .font(.system(size: 14))
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var shouldShowBanner: Bool {
        guard let profile = profileData else { return true }
        
        // Check if essential profile data is missing
        let hasBasicInfo = !profile.firstName.isEmpty && !profile.lastName.isEmpty
        let hasHealthVitals = profile.height > 0 && profile.weight > 0 && profile.age > 0
        let hasActivityLevel = !profile.activityLevel.isEmpty
        let hasGoals = !profile.fitnessGoal.isEmpty
        
        return !hasBasicInfo || !hasHealthVitals || !hasActivityLevel || !hasGoals
    }
    
    private var bannerTitle: String {
        guard let profile = profileData else {
            return "Complete Your Profile"
        }
        
        if profile.firstName.isEmpty || profile.lastName.isEmpty {
            return "Add Your Basic Information"
        } else if profile.height <= 0 || profile.weight <= 0 || profile.age <= 0 {
            return "Update Health Vitals"
        } else if profile.activityLevel.isEmpty {
            return "Set Activity Level"
        } else if profile.fitnessGoal.isEmpty {
            return "Define Your Goals"
        } else {
            return "Complete Your Profile"
        }
    }
    
    private var bannerDescription: String {
        guard let profile = profileData else {
            return "Set up your profile to get personalized meal and workout plans"
        }
        
        if profile.firstName.isEmpty || profile.lastName.isEmpty {
            return "Add your name to personalize your experience"
        } else if profile.height <= 0 || profile.weight <= 0 || profile.age <= 0 {
            return "Enter your height, weight, and age for accurate calorie calculations"
        } else if profile.activityLevel.isEmpty {
            return "Tell us about your activity level to calculate your daily needs"
        } else if profile.fitnessGoal.isEmpty {
            return "Choose your fitness goal for customized meal and workout plans"
        } else {
            return "Complete your profile to unlock personalized recommendations"
        }
    }
}

// Profile data structure for banner logic
struct ProfileData {
    let firstName: String
    let lastName: String
    let height: Float
    let weight: Float
    let age: Int
    let activityLevel: String
    let fitnessGoal: String
}

// Contextual banner for specific views
struct ContextualBanner: View {
    let viewType: BannerViewType
    let profileData: ProfileData?
    let colorScheme: ColorScheme
    let onAction: () -> Void
    
    enum BannerViewType {
        case meals
        case workout
        case home
        case social
    }
    
    var body: some View {
        if shouldShowBanner {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon based on view type
                    ZStack {
                        Circle()
                            .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: iconForViewType)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titleForViewType)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                        
                        Text(descriptionForViewType)
                            .font(.system(size: 13))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onAction) {
                        Text("Setup")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(FitGlideTheme.colors(for: colorScheme).surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var shouldShowBanner: Bool {
        guard let profile = profileData else { return true }
        
        switch viewType {
        case .meals:
            return profile.height <= 0 || profile.weight <= 0 || profile.activityLevel.isEmpty
        case .workout:
            return profile.fitnessGoal.isEmpty
        case .home:
            return profile.firstName.isEmpty || profile.height <= 0 || profile.fitnessGoal.isEmpty
        case .social:
            return profile.firstName.isEmpty || profile.lastName.isEmpty
        }
    }
    
    private var iconForViewType: String {
        switch viewType {
        case .meals: return "fork.knife"
        case .workout: return "dumbbell.fill"
        case .home: return "house.fill"
        case .social: return "person.2.fill"
        }
    }
    
    private var titleForViewType: String {
        switch viewType {
        case .meals: return "Personalized Meal Plans"
        case .workout: return "Custom Workout Plans"
        case .home: return "Complete Your Profile"
        case .social: return "Connect with Friends"
        }
    }
    
    private var descriptionForViewType: String {
        switch viewType {
        case .meals: return "Update your health vitals to get customized meal plans"
        case .workout: return "Set your fitness goals to get personalized workout routines"
        case .home: return "Complete your profile to unlock all features"
        case .social: return "Add your name to connect with friends"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileSetupBanner(
            profileData: nil,
            colorScheme: .light
        )
        
        ContextualBanner(
            viewType: .meals,
            profileData: nil,
            colorScheme: .light
        ) {
            print("Setup tapped")
        }
    }
    .padding()
} 